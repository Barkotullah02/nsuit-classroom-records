package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public DashboardController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> getDashboard(HttpServletRequest request) {
        currentUserService.requireAuth(request);

        // Total devices
        Long totalDevices = jdbc.queryForObject(
                "SELECT COUNT(*) FROM devices WHERE is_deleted = FALSE", Map.of(), Long.class);

        // Total rooms
        Long totalRooms = jdbc.queryForObject(
                "SELECT COUNT(*) FROM rooms WHERE is_active = TRUE", Map.of(), Long.class);

        // LAB rooms
        Long labRooms = jdbc.queryForObject(
                "SELECT COUNT(*) FROM rooms WHERE is_active = TRUE " +
                "AND (room_name LIKE '%LAB%' OR room_name LIKE '%Lab%' OR room_name LIKE '%lab%')",
                Map.of(), Long.class);

        long classroomRooms = (totalRooms != null ? totalRooms : 0) - (labRooms != null ? labRooms : 0);

        // Withdrawn devices
        Long withdrawnDevices = jdbc.queryForObject(
                "SELECT COUNT(*) FROM device_installations WHERE status = 'withdrawn' AND is_deleted = FALSE",
                Map.of(), Long.class);

        // Available devices
        Long availableDevices = jdbc.queryForObject(
                "SELECT COUNT(*) FROM devices d WHERE d.is_deleted = FALSE " +
                "AND d.device_id NOT IN (" +
                "  SELECT device_id FROM device_installations " +
                "  WHERE (status = 'active' OR status = 'withdrawn') AND is_deleted = FALSE" +
                ")",
                Map.of(), Long.class);

        // Devices by type
        List<Map<String, Object>> devicesByType = jdbc.queryForList(
                "SELECT dt.type_name, COUNT(d.device_id) as count " +
                "FROM device_types dt " +
                "LEFT JOIN devices d ON dt.type_id = d.type_id AND d.is_deleted = FALSE " +
                "GROUP BY dt.type_id, dt.type_name ORDER BY count DESC",
                Map.of());

        // Available by type
        List<Map<String, Object>> availableByType = jdbc.queryForList(
                "SELECT dt.type_name, COUNT(d.device_id) as count " +
                "FROM device_types dt " +
                "LEFT JOIN devices d ON dt.type_id = d.type_id AND d.is_deleted = FALSE " +
                "  AND d.device_id NOT IN (" +
                "    SELECT device_id FROM device_installations " +
                "    WHERE (status = 'active' OR status = 'withdrawn') AND is_deleted = FALSE" +
                "  ) " +
                "GROUP BY dt.type_id, dt.type_name HAVING count > 0 ORDER BY count DESC",
                Map.of());

        // Recent activities (last 10)
        List<Map<String, Object>> recentActivities = jdbc.queryForList(
                "SELECT al.log_id, al.action, al.table_name, al.created_at, u.full_name as user_name " +
                "FROM audit_log al JOIN users u ON al.user_id = u.user_id " +
                "ORDER BY al.created_at DESC LIMIT 10",
                Map.of());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total_devices", totalDevices);
        data.put("lab_rooms", labRooms);
        data.put("classroom_rooms", classroomRooms);
        data.put("withdrawn_devices", withdrawnDevices);
        data.put("available_devices", availableDevices);
        data.put("total_rooms", totalRooms);
        data.put("devices_by_type", devicesByType);
        data.put("available_by_type", availableByType);
        data.put("recent_activities", recentActivities);

        return ApiResponse.success("Dashboard statistics retrieved successfully", data);
    }
}
