package com.nsuit.classroomrecords.api;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.service.AuditLogService;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import java.util.HashMap;
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
@RequestMapping("/api/rooms")
public class RoomController {

    private final CurrentUserService currentUserService;
    private final NamedParameterJdbcTemplate jdbc;
    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;

    public RoomController(CurrentUserService currentUserService, NamedParameterJdbcTemplate jdbc,
                          AuditLogService auditLogService, ObjectMapper objectMapper) {
        this.currentUserService = currentUserService;
        this.jdbc = jdbc;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    public ApiResponse<?> getRooms(HttpServletRequest request, @RequestParam(required = false, name = "room_id") Integer roomId) {
        currentUserService.requireAuth(request);
        if (roomId != null) {
            return ApiResponse.success("Room details retrieved successfully", getRoomDetail(roomId));
        }

        List<Map<String, Object>> rooms = jdbc.queryForList("""
                SELECT room_id, room_number, room_name, building, floor, capacity, is_active,
                       (SELECT COUNT(*) FROM device_installations di
                        WHERE di.room_id = r.room_id AND di.status = 'active' AND di.is_deleted = FALSE) AS device_count
                FROM rooms r
                WHERE is_active = TRUE
                ORDER BY room_number
            """, Map.of());
        return ApiResponse.success("Rooms retrieved successfully", rooms);
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Integer>>> createRoom(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireCreate(request);
        String roomNumber = requiredString(payload, "room_number", "Room number and name are required");
        String roomName = requiredString(payload, "room_name", "Room number and name are required");

        Integer existing = jdbc.queryForObject("SELECT COUNT(*) FROM rooms WHERE room_number = :room_number",
            Map.of("room_number", roomNumber), Integer.class);
        if (existing != null && existing > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Room with this number already exists");
        }

        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update("""
                INSERT INTO rooms (room_number, room_name, building, floor, capacity)
                VALUES (:room_number, :room_name, :building, :floor, :capacity)
                """,
                new MapSqlParameterSource()
                        .addValue("room_number", roomNumber)
                        .addValue("room_name", roomName)
                        .addValue("building", nullableString(payload.get("building")))
                        .addValue("floor", payload.get("floor"))
                        .addValue("capacity", payload.get("capacity")),
                keyHolder,
                new String[]{"room_id"});

        Integer roomId = keyHolder.getKey().intValue();
        auditLogService.log(user, "CREATE", "rooms", roomId, null, toJson(payload));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Room created successfully", Map.of("room_id", roomId)));
    }

    @PutMapping
    public ApiResponse<Map<String, Integer>> updateRoom(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireAdmin(request);
        Integer roomId = requiredInteger(payload, "room_id", "Room ID, room number and name are required");
        String roomNumber = requiredString(payload, "room_number", "Room ID, room number and name are required");
        String roomName = requiredString(payload, "room_name", "Room ID, room number and name are required");

        Integer duplicate = jdbc.queryForObject("SELECT COUNT(*) FROM rooms WHERE room_number = :room_number AND room_id != :room_id",
            Map.of("room_number", roomNumber, "room_id", roomId), Integer.class);
        if (duplicate != null && duplicate > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Room with this number already exists");
        }

        Map<String, Object> oldRow = jdbc.query("SELECT * FROM rooms WHERE room_id = :room_id",
                Map.of("room_id", roomId), rs -> rs.next() ? rowToMap(rs) : null);

        int updated = jdbc.update("""
                UPDATE rooms
                SET room_number = :room_number,
                    room_name = :room_name,
                    building = :building,
                    floor = :floor,
                    capacity = :capacity
                WHERE room_id = :room_id AND is_active = TRUE
                """,
                new MapSqlParameterSource()
                        .addValue("room_id", roomId)
                        .addValue("room_number", roomNumber)
                        .addValue("room_name", roomName)
                        .addValue("building", nullableString(payload.get("building")))
                        .addValue("floor", payload.get("floor"))
                        .addValue("capacity", payload.get("capacity")));
        if (updated == 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Failed to update room or room not found");
        }

        auditLogService.log(user, "UPDATE", "rooms", roomId, toJson(oldRow), toJson(payload));
        return ApiResponse.success("Room updated successfully", Map.of("room_id", roomId));
    }

    @DeleteMapping
    public ApiResponse<Map<String, Integer>> deleteRoom(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireAdmin(request);
        Integer roomId = requiredInteger(payload, "room_id", "Room ID is required");

        Integer activeInstallations = jdbc.queryForObject("""
                SELECT COUNT(*) FROM device_installations
                WHERE room_id = :room_id AND status = 'active' AND is_deleted = FALSE
                """, Map.of("room_id", roomId), Integer.class);
        if (activeInstallations != null && activeInstallations > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Cannot delete room with active installations. Please withdraw all devices first.");
        }

        int updated = jdbc.update("UPDATE rooms SET is_active = FALSE WHERE room_id = :room_id", Map.of("room_id", roomId));
        if (updated == 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Failed to delete room or room not found");
        }
        auditLogService.log(user, "SOFT_DELETE", "rooms", roomId);
        return ApiResponse.success("Room deleted successfully", Map.of("room_id", roomId));
    }

    private Map<String, Object> getRoomDetail(Integer roomId) {
        Map<String, Object> room = jdbc.query("""
                SELECT room_id, room_number, room_name, building, floor, capacity, is_active
                FROM rooms WHERE room_id = :room_id AND is_active = TRUE
                """, Map.of("room_id", roomId), rs -> rs.next() ? rowToMap(rs) : null);
        if (room == null) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Room not found");
        }

        List<Map<String, Object>> activeDevices = jdbc.queryForList("""
                SELECT d.device_id, d.device_unique_id, dt.type_name, db.brand_name, d.model, d.serial_number,
                       di.status, di.installation_id, di.installed_date, di.installation_notes,
                       u.full_name AS installed_by_name
                FROM device_installations di
                JOIN devices d ON di.device_id = d.device_id
                LEFT JOIN device_types dt ON d.type_id = dt.type_id
                LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                LEFT JOIN users u ON di.installed_by = u.user_id
                WHERE di.room_id = :room_id AND di.status = 'active' AND di.is_deleted = FALSE
                ORDER BY di.installed_date DESC
                """, Map.of("room_id", roomId));

        List<Map<String, Object>> withdrawnDevices = jdbc.queryForList("""
                SELECT d.device_id, d.device_unique_id, dt.type_name, db.brand_name, d.model, d.serial_number,
                       di.status, di.installation_id, di.installed_date, di.withdrawn_date,
                       di.installation_notes, di.withdrawal_notes,
                       u.full_name AS withdrawn_by_name
                FROM device_installations di
                JOIN devices d ON di.device_id = d.device_id
                LEFT JOIN device_types dt ON d.type_id = dt.type_id
                LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                LEFT JOIN users u ON di.withdrawn_by = u.user_id
                WHERE di.room_id = :room_id AND di.status = 'withdrawn' AND di.is_deleted = FALSE
                ORDER BY di.withdrawn_date DESC
                """, Map.of("room_id", roomId));

        room.put("active_devices", activeDevices);
        room.put("withdrawn_devices", withdrawnDevices);
        room.put("active_device_count", activeDevices.size());
        room.put("withdrawn_device_count", withdrawnDevices.size());
        return room;
    }

    private String requiredString(Map<String, Object> payload, String key, String message) {
        String value = nullableString(payload.get(key));
        if (value == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, message);
        }
        return value;
    }

    private Integer requiredInteger(Map<String, Object> payload, String key, String message) {
        Object value = payload.get(key);
        if (value == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, message);
        }
        return Integer.valueOf(String.valueOf(value));
    }

    private String nullableString(Object value) {
        if (value == null) return null;
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? null : text;
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
