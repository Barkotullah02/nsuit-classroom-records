package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.service.AuditLogService;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/deleted-items")
public class DeletedItemsController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;
    private final AuditLogService auditLogService;

    public DeletedItemsController(NamedParameterJdbcTemplate jdbc,
                                  CurrentUserService currentUserService,
                                  AuditLogService auditLogService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
        this.auditLogService = auditLogService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> getDeletedItems(HttpServletRequest request) {
        currentUserService.requireAdmin(request);

        List<Map<String, Object>> deletedDevices = jdbc.queryForList(
                "SELECT d.device_id, d.device_unique_id, d.type_id, dt.type_name, d.brand_id, db.brand_name, " +
                "d.model, d.serial_number, d.deleted_at, u.full_name as deleted_by_name " +
                "FROM devices d " +
                "LEFT JOIN device_types dt ON d.type_id = dt.type_id " +
                "LEFT JOIN device_brands db ON d.brand_id = db.brand_id " +
                "LEFT JOIN users u ON d.deleted_by = u.user_id " +
                "WHERE d.is_deleted = TRUE ORDER BY d.deleted_at DESC",
                Map.of());

        List<Map<String, Object>> deletedRooms = jdbc.queryForList(
                "SELECT r.room_id, r.room_number, r.room_name, r.building, r.floor, r.capacity, " +
                "r.updated_at as deleted_at " +
                "FROM rooms r WHERE r.is_active = FALSE ORDER BY r.updated_at DESC",
                Map.of());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("devices", deletedDevices);
        data.put("rooms", deletedRooms);
        return ApiResponse.success("Deleted items retrieved successfully", data);
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> restoreItem(@RequestBody Map<String, Object> body,
                                                        HttpServletRequest request) {
        User user = currentUserService.requireAdmin(request);

        String type = (String) body.get("type");
        Object idObj = body.get("id");
        if (type == null || idObj == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Type and ID are required");
        }
        long id = Long.parseLong(idObj.toString());

        if ("device".equals(type)) {
            int updated = jdbc.update(
                    "UPDATE devices SET is_deleted = FALSE, deleted_at = NULL, deleted_by = NULL " +
                    "WHERE device_id = :id AND is_deleted = TRUE",
                    new MapSqlParameterSource("id", id));
            if (updated == 0) throw new ApiException(HttpStatus.NOT_FOUND, "Device not found or already restored");
            auditLogService.log(user, "RESTORE", "devices", (int) id);
            return ApiResponse.success("Device restored successfully", Map.of("device_id", id));
        } else if ("room".equals(type)) {
            int updated = jdbc.update(
                    "UPDATE rooms SET is_active = TRUE WHERE room_id = :id AND is_active = FALSE",
                    new MapSqlParameterSource("id", id));
            if (updated == 0) throw new ApiException(HttpStatus.NOT_FOUND, "Room not found or already active");
            auditLogService.log(user, "RESTORE", "rooms", (int) id);
            return ApiResponse.success("Room restored successfully", Map.of("room_id", id));
        } else {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid type. Must be \"device\" or \"room\"");
        }
    }

    @DeleteMapping
    public ApiResponse<Object> permanentDelete(@RequestBody Map<String, Object> body,
                                               HttpServletRequest request) {
        User user = currentUserService.requireAdmin(request);

        String type = (String) body.get("type");
        Object idObj = body.get("id");
        if (type == null || idObj == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Type and ID are required");
        }
        long id = Long.parseLong(idObj.toString());

        if ("device".equals(type)) {
            // Delete related installations first, then the device
            jdbc.update("DELETE FROM device_installations WHERE device_id = :id",
                    new MapSqlParameterSource("id", id));
            int deleted = jdbc.update(
                    "DELETE FROM devices WHERE device_id = :id AND is_deleted = TRUE",
                    new MapSqlParameterSource("id", id));
            if (deleted == 0) throw new ApiException(HttpStatus.NOT_FOUND, "Device not found or not deleted");
            auditLogService.log(user, "PERMANENT_DELETE", "devices", (int) id);
            return ApiResponse.success("Device permanently deleted", null);
        } else if ("room".equals(type)) {
            int deleted = jdbc.update(
                    "DELETE FROM rooms WHERE room_id = :id AND is_active = FALSE",
                    new MapSqlParameterSource("id", id));
            if (deleted == 0) throw new ApiException(HttpStatus.NOT_FOUND, "Room not found or not deleted");
            auditLogService.log(user, "PERMANENT_DELETE", "rooms", (int) id);
            return ApiResponse.success("Room permanently deleted", null);
        } else {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid type. Must be \"device\" or \"room\"");
        }
    }
}
