package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/room-history")
public class RoomHistoryController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public RoomHistoryController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> getRoomHistory(
            @RequestParam(required = false) Long room_id,
            @RequestParam(required = false) String date_from,
            @RequestParam(required = false) String date_to,
            HttpServletRequest request) {
        currentUserService.requireAuth(request);

        if (room_id == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Room ID is required");
        }

        // Validate date format
        if (date_from != null && !date_from.isBlank() && !date_from.matches("\\d{4}-\\d{2}-\\d{2}")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid date_from format. Use YYYY-MM-DD");
        }
        if (date_to != null && !date_to.isBlank() && !date_to.matches("\\d{4}-\\d{2}-\\d{2}")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid date_to format. Use YYYY-MM-DD");
        }
        if (date_from != null && date_from.isBlank()) date_from = null;
        if (date_to   != null && date_to.isBlank())   date_to   = null;

        // Fetch the room
        List<Map<String, Object>> rooms = jdbc.queryForList(
                "SELECT room_id, room_number, room_name, building, floor, capacity, is_active " +
                "FROM rooms WHERE room_id = :room_id AND is_active = TRUE",
                new MapSqlParameterSource("room_id", room_id));
        if (rooms.isEmpty()) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Room not found");
        }
        Map<String, Object> room = rooms.get(0);

        // Build date conditions
        String activeDateCond = "";
        String withdrawnDateCond = "";
        String historyDateCond = "";
        MapSqlParameterSource params = new MapSqlParameterSource("room_id", room_id);

        if (date_from != null) {
            activeDateCond    += " AND CURDATE() >= :date_from";
            withdrawnDateCond += " AND di.withdrawn_date >= :date_from";
            historyDateCond   += " AND IFNULL(di.withdrawn_date, CURDATE()) >= :date_from";
            params.addValue("date_from", date_from);
        }
        if (date_to != null) {
            activeDateCond    += " AND di.installed_date <= :date_to";
            withdrawnDateCond += " AND di.installed_date <= :date_to";
            historyDateCond   += " AND di.installed_date <= :date_to";
            params.addValue("date_to", date_to);
        }

        // Active devices
        List<Map<String, Object>> activeDevices = jdbc.queryForList(
                "SELECT d.device_id, d.device_unique_id, dt.type_name, db.brand_name, d.model, d.serial_number, " +
                "di.status, di.installation_id, di.installed_date, di.installation_notes, u.full_name as installed_by_name " +
                "FROM device_installations di " +
                "JOIN devices d ON di.device_id = d.device_id " +
                "LEFT JOIN device_types dt ON d.type_id = dt.type_id " +
                "LEFT JOIN device_brands db ON d.brand_id = db.brand_id " +
                "LEFT JOIN users u ON di.installed_by = u.user_id " +
                "WHERE di.room_id = :room_id AND di.status = 'active' AND di.is_deleted = FALSE" +
                activeDateCond + " ORDER BY di.installed_date DESC",
                params);

        // Withdrawn devices
        List<Map<String, Object>> withdrawnDevices = jdbc.queryForList(
                "SELECT d.device_id, d.device_unique_id, dt.type_name, db.brand_name, d.model, d.serial_number, " +
                "di.status, di.installation_id, di.installed_date, di.withdrawn_date, " +
                "di.installation_notes, di.withdrawal_notes, u.full_name as withdrawn_by_name " +
                "FROM device_installations di " +
                "JOIN devices d ON di.device_id = d.device_id " +
                "LEFT JOIN device_types dt ON d.type_id = dt.type_id " +
                "LEFT JOIN device_brands db ON d.brand_id = db.brand_id " +
                "LEFT JOIN users u ON di.withdrawn_by = u.user_id " +
                "WHERE di.room_id = :room_id AND di.status = 'withdrawn' AND di.is_deleted = FALSE" +
                withdrawnDateCond + " ORDER BY di.withdrawn_date DESC",
                params);

        // Add current location for each withdrawn device
        for (Map<String, Object> dev : withdrawnDevices) {
            Object deviceIdObj = dev.get("device_id");
            List<Map<String, Object>> locs = jdbc.queryForList(
                    "SELECT r.room_id, r.room_number, r.room_name, r.building, di.installed_date, di.installation_notes " +
                    "FROM device_installations di JOIN rooms r ON di.room_id = r.room_id " +
                    "WHERE di.device_id = :device_id AND di.status = 'active' AND di.is_deleted = FALSE " +
                    "ORDER BY di.installed_date DESC LIMIT 1",
                    new MapSqlParameterSource("device_id", deviceIdObj));
            dev.put("current_location", locs.isEmpty() ? null : locs.get(0));
        }

        // Complete history
        List<Map<String, Object>> completeHistory = jdbc.queryForList(
                "SELECT di.installation_id, di.device_id, d.device_unique_id, dt.type_name, db.brand_name, " +
                "d.model, d.serial_number, r.room_number, r.room_name, " +
                "di.installed_date, di.withdrawn_date, " +
                "DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room, " +
                "di.status, di.installation_notes, di.withdrawal_notes, " +
                "COALESCE(di.installer_name, u_installed.full_name) as installed_by, " +
                "COALESCE(di.withdrawer_name, u_withdrawn.full_name) as withdrawn_by " +
                "FROM device_installations di " +
                "JOIN devices d ON di.device_id = d.device_id " +
                "JOIN rooms r ON di.room_id = r.room_id " +
                "LEFT JOIN device_types dt ON d.type_id = dt.type_id " +
                "LEFT JOIN device_brands db ON d.brand_id = db.brand_id " +
                "LEFT JOIN users u_installed ON di.installed_by = u_installed.user_id " +
                "LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id " +
                "WHERE di.room_id = :room_id AND di.is_deleted = FALSE" +
                historyDateCond + " ORDER BY di.installed_date DESC",
                params);

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("active_count", activeDevices.size());
        stats.put("withdrawn_count", withdrawnDevices.size());
        stats.put("total_history_records", completeHistory.size());

        Map<String, Object> responseData = new LinkedHashMap<>();
        responseData.put("room", room);
        responseData.put("active_devices", activeDevices);
        responseData.put("withdrawn_devices", withdrawnDevices);
        responseData.put("complete_history", completeHistory);
        responseData.put("statistics", stats);

        return ApiResponse.success("Room history retrieved successfully", responseData);
    }
}
