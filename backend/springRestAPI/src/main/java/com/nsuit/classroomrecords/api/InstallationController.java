package com.nsuit.classroomrecords.api;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.service.AuditLogService;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
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
@RequestMapping("/api/installations")
public class InstallationController {

    private final CurrentUserService currentUserService;
    private final NamedParameterJdbcTemplate jdbc;
    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;

    public InstallationController(CurrentUserService currentUserService, NamedParameterJdbcTemplate jdbc,
                                  AuditLogService auditLogService, ObjectMapper objectMapper) {
        this.currentUserService = currentUserService;
        this.jdbc = jdbc;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getInstallations(
            HttpServletRequest request,
            @RequestParam(required = false, name = "device_id") Integer deviceId,
            @RequestParam(required = false, name = "room_id") Integer roomId,
            @RequestParam(required = false, name = "status") String status,
            @RequestParam(required = false, name = "installation_type") String installationType) {
        currentUserService.requireAuth(request);

        StringBuilder where = new StringBuilder("WHERE di.is_deleted = FALSE");
        MapSqlParameterSource params = new MapSqlParameterSource();
        if (deviceId != null) {
            where.append(" AND di.device_id = :device_id");
            params.addValue("device_id", deviceId);
        }
        if (roomId != null) {
            where.append(" AND di.room_id = :room_id");
            params.addValue("room_id", roomId);
        }
        if (status != null && !status.isBlank()) {
            where.append(" AND di.status = :status");
            params.addValue("status", status);
        }
        if (installationType != null && !installationType.isBlank()) {
            where.append(" AND di.installation_type = :installation_type");
            params.addValue("installation_type", installationType);
        }

        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT di.installation_id, di.device_id, d.device_unique_id, dt.type_name, db.brand_name,
                       d.model, d.serial_number, d.device_status, d.current_issue,
                       d.storage_location AS device_storage_location, di.room_id, r.room_number, r.room_name, r.building,
                       di.installed_date, di.withdrawn_date,
                       DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) AS days_in_room,
                       di.status, di.installation_type, di.installation_notes, di.withdrawal_notes, di.team_members,
                       di.issue_at_withdrawal, di.storage_location AS withdrawal_storage_location,
                       di.gate_pass_number, di.gate_pass_date,
                       COALESCE(di.installer_name, u_installed.full_name) AS installed_by_name,
                       di.installer_id AS installed_by_id,
                       COALESCE(di.withdrawer_name, u_withdrawn.full_name) AS withdrawn_by_name,
                       di.withdrawer_id AS withdrawn_by_id,
                       u_data_entry.full_name AS data_entry_by_name,
                       di.created_at
                FROM device_installations di
                JOIN devices d ON di.device_id = d.device_id
                JOIN device_types dt ON d.type_id = dt.type_id
                JOIN device_brands db ON d.brand_id = db.brand_id
                JOIN rooms r ON di.room_id = r.room_id
                LEFT JOIN users u_installed ON di.installed_by = u_installed.user_id
                LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id
                LEFT JOIN users u_data_entry ON di.data_entry_by = u_data_entry.user_id
                """ + where + " ORDER BY di.installed_date DESC", params);

        return ApiResponse.success("Installations retrieved successfully", rows);
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Integer>>> createInstallation(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireCreate(request);
        Map<String, String> errors = new LinkedHashMap<>();
        requireField(payload, "device_id", errors);
        requireField(payload, "room_id", errors);
        requireField(payload, "installed_date", errors);
        if (!errors.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Validation failed", errors);
        }

        String status = nullableString(payload.get("status"));
        if (status == null) {
            status = "active";
        }
        String withdrawnDateText = nullableString(payload.get("withdrawn_date"));
        if (withdrawnDateText != null && !"withdrawn".equals(status)) {
            status = "withdrawn";
        }

        if ("active".equals(status)) {
            Integer active = jdbc.queryForObject("SELECT COUNT(*) FROM device_installations WHERE device_id = :device_id AND status = 'active' AND is_deleted = FALSE",
                    Map.of("device_id", toInteger(payload.get("device_id"))), Integer.class);
            if (active != null && active > 0) {
                throw new ApiException(HttpStatus.CONFLICT, "Device already has an active installation. Please withdraw it first.");
            }
        }

        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update("""
                INSERT INTO device_installations
                (device_id, room_id, installed_date, installed_by, installer_name, installer_id,
                 installation_notes, team_members, installation_type, gate_pass_number, gate_pass_date,
                 withdrawn_date, withdrawn_by, withdrawer_name, withdrawer_id, withdrawal_notes,
                 issue_at_withdrawal, storage_location, data_entry_by, status)
                VALUES
                (:device_id, :room_id, :installed_date, :installed_by, :installer_name, :installer_id,
                 :installation_notes, :team_members, :installation_type, :gate_pass_number, :gate_pass_date,
                 :withdrawn_date, :withdrawn_by, :withdrawer_name, :withdrawer_id, :withdrawal_notes,
                 :issue_at_withdrawal, :storage_location, :data_entry_by, :status)
                """,
                new MapSqlParameterSource()
                        .addValue("device_id", toInteger(payload.get("device_id")))
                        .addValue("room_id", toInteger(payload.get("room_id")))
                        .addValue("installed_date", toSqlDate(payload.get("installed_date")))
                        .addValue("installed_by", user.getId())
                        .addValue("installer_name", nullableString(payload.get("installer_name")))
                        .addValue("installer_id", nullableString(payload.get("installer_id")))
                        .addValue("installation_notes", nullableString(payload.get("installation_notes")))
                        .addValue("team_members", nullableString(payload.get("team_members")))
                        .addValue("installation_type", nullableString(payload.get("installation_type")))
                        .addValue("gate_pass_number", nullableString(payload.get("gate_pass_number")))
                        .addValue("gate_pass_date", toSqlDate(payload.get("gate_pass_date")))
                        .addValue("withdrawn_date", toSqlDate(payload.get("withdrawn_date")))
                        .addValue("withdrawn_by", user.getId())
                        .addValue("withdrawer_name", nullableString(payload.get("withdrawer_name")))
                        .addValue("withdrawer_id", nullableString(payload.get("withdrawer_id")))
                        .addValue("withdrawal_notes", nullableString(payload.get("withdrawal_notes")))
                        .addValue("issue_at_withdrawal", nullableString(payload.get("issue_at_withdrawal")))
                        .addValue("storage_location", nullableString(payload.get("storage_location")))
                        .addValue("data_entry_by", user.getId())
                        .addValue("status", status),
                keyHolder,
                new String[]{"installation_id"});

        Integer installationId = keyHolder.getKey().intValue();
        auditLogService.log(user, "CREATE", "device_installations", installationId, null, toJson(payload));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Device installed successfully", Map.of("installation_id", installationId)));
    }

    @PutMapping
    public ApiResponse<Map<String, Object>> withdrawInstallation(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireAdmin(request);
        Integer installationId = toInteger(payload.get("installation_id"));
        if (installationId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Installation ID is required");
        }
        String withdrawnDate = nullableString(payload.get("withdrawn_date"));
        if (withdrawnDate == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Withdrawn date is required");
        }

        Map<String, Object> oldValues = jdbc.query("SELECT * FROM device_installations WHERE installation_id = :installation_id",
                Map.of("installation_id", installationId), rs -> rs.next() ? rowToMap(rs) : null);
        if (oldValues == null) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Installation record not found");
        }

        jdbc.update("""
                UPDATE device_installations SET
                    withdrawn_date = :withdrawn_date,
                    withdrawn_by = :withdrawn_by,
                    withdrawer_name = :withdrawer_name,
                    withdrawer_id = :withdrawer_id,
                    withdrawal_notes = :withdrawal_notes,
                    issue_at_withdrawal = :issue_at_withdrawal,
                    storage_location = :storage_location,
                    data_entry_by = :data_entry_by,
                    status = 'withdrawn'
                WHERE installation_id = :installation_id
                """,
                new MapSqlParameterSource()
                        .addValue("installation_id", installationId)
                        .addValue("withdrawn_date", Date.valueOf(withdrawnDate))
                        .addValue("withdrawn_by", user.getId())
                        .addValue("withdrawer_name", nullableString(payload.get("withdrawer_name")))
                        .addValue("withdrawer_id", nullableString(payload.get("withdrawer_id")))
                        .addValue("withdrawal_notes", nullableString(payload.get("withdrawal_notes")))
                        .addValue("issue_at_withdrawal", nullableString(payload.get("issue_at_withdrawal")))
                        .addValue("storage_location", nullableString(payload.get("storage_location")))
                        .addValue("data_entry_by", user.getId()));

        auditLogService.log(user, "UPDATE", "device_installations", installationId, toJson(oldValues), toJson(payload));
        return ApiResponse.success("Device withdrawn successfully", Map.of());
    }

    @DeleteMapping
    public ApiResponse<Map<String, Object>> deleteInstallation(HttpServletRequest request, @RequestParam(name = "installation_id") Integer installationId) {
        User user = currentUserService.requireAdmin(request);
        if (installationId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Installation ID is required");
        }

        jdbc.update("""
                UPDATE device_installations
                SET is_deleted = TRUE, deleted_at = NOW(), deleted_by = :deleted_by
                WHERE installation_id = :installation_id
                """, Map.of("deleted_by", user.getId(), "installation_id", installationId));
        auditLogService.log(user, "SOFT_DELETE", "device_installations", installationId);
        return ApiResponse.success("Installation record deleted successfully", Map.of());
    }

    private void requireField(Map<String, Object> payload, String field, Map<String, String> errors) {
        Object value = payload.get(field);
        if (value == null || String.valueOf(value).trim().isEmpty()) {
            String label = field.replace('_', ' ');
            errors.put(field, Character.toUpperCase(label.charAt(0)) + label.substring(1) + " is required");
        }
    }

    private Integer toInteger(Object value) {
        if (value == null || String.valueOf(value).isBlank()) return null;
        return Integer.valueOf(String.valueOf(value));
    }

    private String nullableString(Object value) {
        if (value == null) return null;
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? null : text;
    }

    private Date toSqlDate(Object value) {
        String text = nullableString(value);
        if (text == null) return null;
        try {
            return Date.valueOf(LocalDate.parse(text));
        } catch (DateTimeParseException ex) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Validation failed", Map.of(text.contains(":") ? "date" : guessDateField(value), "Date must be in YYYY-MM-DD format"));
        }
    }

    private String guessDateField(Object value) {
        return "date";
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
