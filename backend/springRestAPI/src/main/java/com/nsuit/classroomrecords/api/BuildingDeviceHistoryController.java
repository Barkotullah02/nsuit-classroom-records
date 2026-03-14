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
@RequestMapping("/api/building-device-history")
public class BuildingDeviceHistoryController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public BuildingDeviceHistoryController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> getBuildingHistory(
            @RequestParam(required = false) String building,
            @RequestParam(required = false) String floor,
            @RequestParam(defaultValue = "all") String status,
            @RequestParam(required = false) String date_from,
            @RequestParam(required = false) String date_to,
            HttpServletRequest request) {
        currentUserService.requireAuth(request);

        if (building == null || building.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Building is required");
        }
        building = building.trim().toUpperCase();
        status = status.toLowerCase();

        if (!List.of("all", "active", "withdrawn").contains(status)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid status. Use all, active, or withdrawn");
        }
        if (date_from != null && !date_from.isBlank() && !date_from.matches("\\d{4}-\\d{2}-\\d{2}")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid date_from format. Use YYYY-MM-DD");
        }
        if (date_to != null && !date_to.isBlank() && !date_to.matches("\\d{4}-\\d{2}-\\d{2}")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid date_to format. Use YYYY-MM-DD");
        }
        if (date_from != null && date_from.isBlank()) date_from = null;
        if (date_to   != null && date_to.isBlank())   date_to   = null;
        if (floor     != null && floor.isBlank())     floor     = null;

        StringBuilder where = new StringBuilder("WHERE di.is_deleted = FALSE");
        MapSqlParameterSource params = new MapSqlParameterSource();
        params.addValue("building", building);
        params.addValue("building_regexp", "^" + building);

        where.append(" AND (UPPER(r.building) = :building OR " +
                "(COALESCE(r.building, '') = '' AND UPPER(r.room_number) REGEXP :building_regexp))");

        if (floor != null) {
            where.append(" AND (r.floor = :floor OR (COALESCE(r.floor, '') = '' AND r.room_number REGEXP :floor_regexp))");
            params.addValue("floor", floor);
            params.addValue("floor_regexp", "[[:space:]]" + floor + "[0-9]{2}");
        }
        if (!"all".equals(status)) {
            where.append(" AND di.status = :status");
            params.addValue("status", status);
        }
        if (date_from != null) {
            where.append(" AND IFNULL(di.withdrawn_date, CURDATE()) >= :date_from");
            params.addValue("date_from", date_from);
        }
        if (date_to != null) {
            where.append(" AND di.installed_date <= :date_to");
            params.addValue("date_to", date_to);
        }

        String sql = "SELECT di.installation_id, r.room_id, r.room_number, r.room_name, " +
                "COALESCE(r.building, '') AS building, COALESCE(r.floor, '') AS floor, " +
                "d.device_id, d.device_unique_id, d.model, d.serial_number, " +
                "dt.type_name, db.brand_name, " +
                "di.installed_date, di.withdrawn_date, " +
                "DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) AS days_in_room, " +
                "di.status, di.installation_notes, di.withdrawal_notes, " +
                "COALESCE(di.installer_name, u_i.full_name) AS installed_by, " +
                "COALESCE(di.withdrawer_name, u_w.full_name) AS withdrawn_by " +
                "FROM device_installations di " +
                "JOIN rooms r ON di.room_id = r.room_id " +
                "JOIN devices d ON di.device_id = d.device_id " +
                "LEFT JOIN device_types dt ON d.type_id = dt.type_id " +
                "LEFT JOIN device_brands db ON d.brand_id = db.brand_id " +
                "LEFT JOIN users u_i ON di.installed_by = u_i.user_id " +
                "LEFT JOIN users u_w ON di.withdrawn_by = u_w.user_id " +
                where +
                " ORDER BY r.room_number, di.installed_date DESC";

        List<Map<String, Object>> records = jdbc.queryForList(sql, params);

        long activeCount = records.stream().filter(r -> "active".equals(r.get("status"))).count();
        long withdrawnCount = records.stream().filter(r -> "withdrawn".equals(r.get("status"))).count();
        Set<Object> roomIds = new HashSet<>();
        records.forEach(r -> roomIds.add(r.get("room_id")));

        Map<String, Object> filters = new LinkedHashMap<>();
        filters.put("building", building);
        filters.put("floor", floor);
        filters.put("status", status);
        filters.put("date_from", date_from);
        filters.put("date_to", date_to);

        Map<String, Object> statistics = new LinkedHashMap<>();
        statistics.put("total_records", records.size());
        statistics.put("active_count", activeCount);
        statistics.put("withdrawn_count", withdrawnCount);
        statistics.put("room_count", roomIds.size());

        Map<String, Object> responseData = new LinkedHashMap<>();
        responseData.put("filters", filters);
        responseData.put("statistics", statistics);
        responseData.put("records", records);

        return ApiResponse.success("Building device history retrieved successfully", responseData);
    }
}
