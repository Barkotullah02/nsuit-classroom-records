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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;

@RestController
@RequestMapping("/api/invalid-installation-dates")
public class InvalidInstallationDatesController {

    private final CurrentUserService currentUserService;
    private final NamedParameterJdbcTemplate jdbc;
    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;

    public InvalidInstallationDatesController(CurrentUserService currentUserService, NamedParameterJdbcTemplate jdbc,
                                              AuditLogService auditLogService, ObjectMapper objectMapper) {
        this.currentUserService = currentUserService;
        this.jdbc = jdbc;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getInvalidInstallations(HttpServletRequest request) {
        currentUserService.requireAuth(request);
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT di.installation_id, di.device_id, d.device_unique_id, dt.type_name, db.brand_name, d.model,
                       di.room_id, r.room_number, r.room_name, r.building,
                       di.installed_date, di.withdrawn_date, di.gate_pass_date, di.status,
                       di.installation_type, di.gate_pass_number, di.created_at, di.updated_at,
                       CASE
                           WHEN di.installed_date IS NULL OR CAST(di.installed_date AS CHAR) = '0000-00-00' THEN 'MISSING_OR_ZERO_INSTALLED_DATE'
                           WHEN di.status = 'withdrawn' AND (di.withdrawn_date IS NULL OR CAST(di.withdrawn_date AS CHAR) = '0000-00-00') THEN 'WITHDRAWN_WITHOUT_WITHDRAWN_DATE'
                           WHEN di.withdrawn_date IS NOT NULL AND CAST(di.withdrawn_date AS CHAR) != '0000-00-00'
                                AND di.installed_date IS NOT NULL AND CAST(di.installed_date AS CHAR) != '0000-00-00'
                                AND di.withdrawn_date < di.installed_date THEN 'WITHDRAWN_BEFORE_INSTALLED'
                           ELSE 'UNKNOWN'
                       END AS invalid_reason
                FROM device_installations di
                JOIN devices d ON di.device_id = d.device_id
                JOIN device_types dt ON d.type_id = dt.type_id
                JOIN device_brands db ON d.brand_id = db.brand_id
                JOIN rooms r ON di.room_id = r.room_id
                WHERE di.is_deleted = FALSE AND (
                    di.installed_date IS NULL OR CAST(di.installed_date AS CHAR) = '0000-00-00' OR
                    (di.status = 'withdrawn' AND (di.withdrawn_date IS NULL OR CAST(di.withdrawn_date AS CHAR) = '0000-00-00')) OR
                    (di.withdrawn_date IS NOT NULL AND CAST(di.withdrawn_date AS CHAR) != '0000-00-00' AND
                     di.installed_date IS NOT NULL AND CAST(di.installed_date AS CHAR) != '0000-00-00' AND
                     di.withdrawn_date < di.installed_date)
                )
                ORDER BY di.updated_at DESC, di.created_at DESC
                """, Map.of());
        return ApiResponse.success("Invalid installation dates retrieved successfully", rows);
    }

    @PutMapping
    public ApiResponse<Map<String, Object>> updateDates(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User user = currentUserService.requireAdmin(request);
        Integer installationId = toInteger(payload.get("installation_id"));
        if (installationId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Installation ID is required");
        }
        if (!payload.containsKey("installed_date") && !payload.containsKey("withdrawn_date") && !payload.containsKey("gate_pass_date")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "At least one date field is required (installed_date, withdrawn_date, gate_pass_date)");
        }

        LocalDate installedDate = parseNullableDate(payload.get("installed_date"), "installed_date");
        LocalDate withdrawnDate = parseNullableDate(payload.get("withdrawn_date"), "withdrawn_date");
        LocalDate gatePassDate = parseNullableDate(payload.get("gate_pass_date"), "gate_pass_date");

        Map<String, Object> existing = jdbc.query("SELECT * FROM device_installations WHERE installation_id = :installation_id AND is_deleted = FALSE",
                Map.of("installation_id", installationId), rs -> rs.next() ? rowToMap(rs) : null);
        if (existing == null) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Installation record not found");
        }

        LocalDate finalInstalled = payload.containsKey("installed_date") ? installedDate : toLocalDate(existing.get("installed_date"));
        LocalDate finalWithdrawn = payload.containsKey("withdrawn_date") ? withdrawnDate : toLocalDate(existing.get("withdrawn_date"));
        LocalDate finalGatePass = payload.containsKey("gate_pass_date") ? gatePassDate : toLocalDate(existing.get("gate_pass_date"));

        Map<String, String> errors = new LinkedHashMap<>();
        if (finalInstalled != null && finalWithdrawn != null && finalWithdrawn.isBefore(finalInstalled)) {
            errors.put("date_order", "Withdrawn date cannot be earlier than installed date after update");
        }
        if (!errors.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Validation failed", errors);
        }

        StringBuilder sql = new StringBuilder("UPDATE device_installations SET ");
        MapSqlParameterSource params = new MapSqlParameterSource().addValue("installation_id", installationId).addValue("data_entry_by", user.getId());
        boolean first = true;
        if (payload.containsKey("installed_date")) {
            sql.append(first ? "" : ", ").append("installed_date = :installed_date");
            params.addValue("installed_date", toSqlDate(installedDate));
            first = false;
        }
        if (payload.containsKey("withdrawn_date")) {
            sql.append(first ? "" : ", ").append("withdrawn_date = :withdrawn_date");
            params.addValue("withdrawn_date", toSqlDate(withdrawnDate));
            first = false;
        }
        if (payload.containsKey("gate_pass_date")) {
            sql.append(first ? "" : ", ").append("gate_pass_date = :gate_pass_date");
            params.addValue("gate_pass_date", toSqlDate(gatePassDate));
            first = false;
        }
        sql.append(first ? "data_entry_by = :data_entry_by" : ", data_entry_by = :data_entry_by");
        sql.append(" WHERE installation_id = :installation_id");
        jdbc.update(sql.toString(), params);

        Map<String, Object> newValues = jdbc.query("SELECT installation_id, installed_date, withdrawn_date, gate_pass_date FROM device_installations WHERE installation_id = :installation_id",
                Map.of("installation_id", installationId), rs -> rs.next() ? rowToMap(rs) : null);
        Map<String, Object> oldDateValues = new LinkedHashMap<>();
        oldDateValues.put("installed_date", existing.get("installed_date"));
        oldDateValues.put("withdrawn_date", existing.get("withdrawn_date"));
        oldDateValues.put("gate_pass_date", existing.get("gate_pass_date"));

        auditLogService.log(user, "UPDATE_INVALID_DATES", "device_installations", installationId,
            toJson(oldDateValues),
                toJson(newValues));
        return ApiResponse.success("Installation dates updated successfully", newValues);
    }

    private Integer toInteger(Object value) {
        if (value == null || String.valueOf(value).isBlank()) return null;
        return Integer.valueOf(String.valueOf(value));
    }

    private LocalDate parseNullableDate(Object value, String field) {
        if (value == null) return null;
        String text = String.valueOf(value).trim();
        if (text.isEmpty() || "0000-00-00".equals(text) || "null".equalsIgnoreCase(text)) {
            return null;
        }
        try {
            return LocalDate.parse(text);
        } catch (DateTimeParseException ex) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Validation failed", Map.of(field, toLabel(field) + " must be a valid date in YYYY-MM-DD format"));
        }
    }

    private String toLabel(String field) {
        return Character.toUpperCase(field.charAt(0)) + field.substring(1).replace('_', ' ');
    }

    private Date toSqlDate(LocalDate value) {
        return value == null ? null : Date.valueOf(value);
    }

    private LocalDate toLocalDate(Object value) {
        if (value == null) return null;
        if (value instanceof Date date) return date.toLocalDate();
        String text = String.valueOf(value);
        if (text.isBlank() || "0000-00-00".equals(text)) return null;
        return LocalDate.parse(text);
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
