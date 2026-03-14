package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/device-history")
public class DeviceHistoryController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public DeviceHistoryController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getDeviceHistory(
            @RequestParam(required = false) Long device_id,
            HttpServletRequest request) {
        currentUserService.requireAuth(request);

        if (device_id == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Device ID is required");
        }

        String sql = "SELECT " +
                "di.installation_id, di.device_id, " +
                "r.room_number, r.room_name, " +
                "di.installed_date, di.withdrawn_date, " +
                "DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room, " +
                "di.status, di.installation_notes, di.withdrawal_notes, " +
                "di.gate_pass_number, di.gate_pass_date, " +
                "COALESCE(di.installer_name, u_installed.full_name) as installed_by, " +
                "di.installer_id as installed_by_id, " +
                "COALESCE(di.withdrawer_name, u_withdrawn.full_name) as withdrawn_by, " +
                "di.withdrawer_id as withdrawn_by_id, " +
                "u_data_entry.full_name as data_entry_by " +
                "FROM device_installations di " +
                "JOIN rooms r ON di.room_id = r.room_id " +
                "LEFT JOIN users u_installed ON di.installed_by = u_installed.user_id " +
                "LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id " +
                "LEFT JOIN users u_data_entry ON di.data_entry_by = u_data_entry.user_id " +
                "WHERE di.device_id = :device_id AND di.is_deleted = FALSE " +
                "ORDER BY di.installed_date DESC";

        List<Map<String, Object>> history = jdbc.queryForList(sql,
                new MapSqlParameterSource("device_id", device_id));

        return ApiResponse.success("Device history retrieved successfully", history);
    }
}
