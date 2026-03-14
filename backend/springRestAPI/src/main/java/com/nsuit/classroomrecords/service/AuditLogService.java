package com.nsuit.classroomrecords.service;

import com.nsuit.classroomrecords.model.User;
import java.util.Map;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AuditLogService {

    private final NamedParameterJdbcTemplate jdbcTemplate;

    public AuditLogService(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void log(User user, String action, String tableName, Integer recordId) {
        log(user, action, tableName, recordId, null, null);
    }

    public void log(User user, String action, String tableName, Integer recordId, String oldValues, String newValues) {
        jdbcTemplate.update(
                """
                INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values)
                VALUES (:user_id, :action, :table_name, :record_id, :old_values, :new_values)
                """,
            new MapSqlParameterSource()
                .addValue("user_id", user.getId())
                .addValue("action", action)
                .addValue("table_name", tableName)
                .addValue("record_id", recordId)
                .addValue("old_values", oldValues)
                .addValue("new_values", newValues)
        );
    }
}
