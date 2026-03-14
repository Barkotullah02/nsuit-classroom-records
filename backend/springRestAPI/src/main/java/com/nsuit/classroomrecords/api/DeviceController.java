package com.nsuit.classroomrecords.api;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.service.AuditLogService;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import java.sql.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/devices")
public class DeviceController {

    private final CurrentUserService currentUserService;
    private final NamedParameterJdbcTemplate jdbc;
    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;

    public DeviceController(CurrentUserService currentUserService, NamedParameterJdbcTemplate jdbc,
                            AuditLogService auditLogService, ObjectMapper objectMapper) {
        this.currentUserService = currentUserService;
        this.jdbc = jdbc;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getDevices(
            HttpServletRequest request,
            @RequestParam(required = false, name = "device_id") Integer deviceId,
            @RequestParam(required = false, name = "device_unique_id") String deviceUniqueId,
            @RequestParam(required = false, name = "type_id") Integer typeId,
            @RequestParam(required = false, name = "brand_id") Integer brandId,
            @RequestParam(required = false, name = "room_id") Integer roomId) {
        currentUserService.requireAuth(request);

        StringBuilder where = new StringBuilder("WHERE d.is_deleted = FALSE");
        MapSqlParameterSource params = new MapSqlParameterSource();
        if (deviceId != null) {
            where.append(" AND d.device_id = :device_id");
            params.addValue("device_id", deviceId);
        }
        if (deviceUniqueId != null && !deviceUniqueId.isBlank()) {
            where.append(" AND d.device_unique_id LIKE :device_unique_id");
            params.addValue("device_unique_id", "%" + deviceUniqueId + "%");
        }
        if (typeId != null) {
            where.append(" AND d.type_id = :type_id");
            params.addValue("type_id", typeId);
        }
        if (brandId != null) {
            where.append(" AND d.brand_id = :brand_id");
            params.addValue("brand_id", brandId);
        }
        if (roomId != null) {
            where.append(" AND di.room_id = :room_id AND di.status = 'active'");
            params.addValue("room_id", roomId);
        }

        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT d.device_id, d.device_unique_id, d.type_id, dt.type_name, d.brand_id, db.brand_name,
                       d.model, d.serial_number, d.purchase_date, d.warranty_period, d.notes, d.is_active,
                       d.created_at, r.room_id AS current_room_id, r.room_number AS current_room_number,
                       r.room_name AS current_room_name, r.building AS current_building,
                       di.installed_date AS current_installation_date,
                       DATEDIFF(CURDATE(), di.installed_date) AS days_in_current_room,
                       (SELECT MIN(inst.installed_date) FROM device_installations inst
                        WHERE inst.device_id = d.device_id AND inst.is_deleted = FALSE) AS first_installation_date,
                       DATEDIFF(CURDATE(), (SELECT MIN(inst.installed_date) FROM device_installations inst
                        WHERE inst.device_id = d.device_id AND inst.is_deleted = FALSE)) AS total_lifetime_days
                FROM devices d
                LEFT JOIN device_types dt ON d.type_id = dt.type_id
                LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                LEFT JOIN device_installations di ON d.device_id = di.device_id AND di.status = 'active' AND di.is_deleted = FALSE
                LEFT JOIN rooms r ON di.room_id = r.room_id
                """ + where + " ORDER BY d.device_unique_id", params);

        return ApiResponse.success("Devices retrieved successfully", rows);
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Integer>>> createDevice(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireCreate(request);
        Map<String, String> errors = new LinkedHashMap<>();
        requireField(payload, "device_unique_id", errors);
        requireField(payload, "type_id", errors);
        requireField(payload, "brand_id", errors);
        if (!errors.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Validation failed", errors);
        }

        String uniqueId = String.valueOf(payload.get("device_unique_id"));
        Integer duplicate = jdbc.queryForObject("SELECT COUNT(*) FROM devices WHERE device_unique_id = :device_unique_id",
            Map.of("device_unique_id", uniqueId), Integer.class);
        if (duplicate != null && duplicate > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Device with this unique ID already exists");
        }

        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update("""
                INSERT INTO devices (device_unique_id, type_id, brand_id, model, serial_number, purchase_date, warranty_period, notes)
                VALUES (:device_unique_id, :type_id, :brand_id, :model, :serial_number, :purchase_date, :warranty_period, :notes)
                """,
                new MapSqlParameterSource()
                        .addValue("device_unique_id", uniqueId)
                        .addValue("type_id", toInteger(payload.get("type_id")))
                        .addValue("brand_id", toInteger(payload.get("brand_id")))
                        .addValue("model", nullableString(payload.get("model")))
                        .addValue("serial_number", nullableString(payload.get("serial_number")))
                        .addValue("purchase_date", toSqlDate(payload.get("purchase_date")))
                        .addValue("warranty_period", toIntegerNullable(payload.get("warranty_period")))
                        .addValue("notes", nullableString(payload.get("notes"))),
                keyHolder,
                new String[]{"device_id"});

        Integer deviceId = keyHolder.getKey().intValue();
        auditLogService.log(user, "CREATE", "devices", deviceId, null, toJson(payload));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Device created successfully", Map.of("device_id", deviceId)));
    }

    @PutMapping
    public ApiResponse<Map<String, Object>> updateDevice(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireAdmin(request);
        Integer deviceId = toInteger(payload.get("device_id"));
        if (deviceId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Device ID is required");
        }

        Map<String, Object> oldValues = jdbc.query("SELECT * FROM devices WHERE device_id = :device_id",
                Map.of("device_id", deviceId), rs -> rs.next() ? rowToMap(rs) : null);
        if (oldValues == null) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Device not found");
        }

        jdbc.update("""
                UPDATE devices SET
                    device_unique_id = :device_unique_id,
                    type_id = :type_id,
                    brand_id = :brand_id,
                    model = :model,
                    serial_number = :serial_number,
                    purchase_date = :purchase_date,
                    warranty_period = :warranty_period,
                    notes = :notes,
                    is_active = :is_active
                WHERE device_id = :device_id
                """,
                new MapSqlParameterSource()
                        .addValue("device_id", deviceId)
                        .addValue("device_unique_id", nullableString(payload.get("device_unique_id")))
                        .addValue("type_id", toInteger(payload.get("type_id")))
                        .addValue("brand_id", toInteger(payload.get("brand_id")))
                        .addValue("model", nullableString(payload.get("model")))
                        .addValue("serial_number", nullableString(payload.get("serial_number")))
                        .addValue("purchase_date", toSqlDate(payload.get("purchase_date")))
                        .addValue("warranty_period", toIntegerNullable(payload.get("warranty_period")))
                        .addValue("notes", nullableString(payload.get("notes")))
                        .addValue("is_active", payload.get("is_active") == null ? Boolean.TRUE : payload.get("is_active")));

        auditLogService.log(user, "UPDATE", "devices", deviceId, toJson(oldValues), toJson(payload));
        return ApiResponse.success("Device updated successfully", Map.of());
    }

    @DeleteMapping
    public ApiResponse<Map<String, Integer>> deleteDevice(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireAdmin(request);
        Integer deviceId = toInteger(payload.get("device_id"));
        if (deviceId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Device ID is required");
        }

        Integer activeInstallations = jdbc.queryForObject("""
                SELECT COUNT(*) FROM device_installations
                WHERE device_id = :device_id AND status = 'active' AND is_deleted = FALSE
                """, Map.of("device_id", deviceId), Integer.class);
        if (activeInstallations != null && activeInstallations > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Cannot delete device with active installations. Please withdraw the device first.");
        }

        int updated = jdbc.update("""
                UPDATE devices SET is_deleted = TRUE, deleted_at = NOW(), deleted_by = :deleted_by
                WHERE device_id = :device_id
                """, Map.of("deleted_by", user.getId(), "device_id", deviceId));
        if (updated == 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Failed to delete device or device not found");
        }

        auditLogService.log(user, "SOFT_DELETE", "devices", deviceId);
        return ApiResponse.success("Device deleted successfully", Map.of("device_id", deviceId));
    }

    private void requireField(Map<String, Object> payload, String field, Map<String, String> errors) {
        Object value = payload.get(field);
        if (value == null || String.valueOf(value).trim().isEmpty()) {
            errors.put(field, field.replace('_', ' ').substring(0, 1).toUpperCase() + field.replace('_', ' ').substring(1) + " is required");
        }
    }

    private Integer toInteger(Object value) {
        if (value == null || String.valueOf(value).isBlank()) return null;
        return Integer.valueOf(String.valueOf(value));
    }

    private Integer toIntegerNullable(Object value) {
        return toInteger(value);
    }

    private String nullableString(Object value) {
        if (value == null) return null;
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? null : text;
    }

    private Date toSqlDate(Object value) {
        String text = nullableString(value);
        return text == null ? null : Date.valueOf(text);
    }

    private String toJson(Object value) {
        try {
            return value == null ? null : objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            return null;
        }
    }

    private Map<String, Object> rowToMap(java.sql.ResultSet rs) throws java.sql.SQLException {
        Map<String, Object> map = new LinkedHashMap<>();
        var meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            map.put(meta.getColumnLabel(i), rs.getObject(i));
        }
        return map;
    }
}
