package com.nsuit.classroomrecords.api;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.model.enums.UserRole;
import com.nsuit.classroomrecords.service.AuditLogService;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final CurrentUserService currentUserService;
    private final NamedParameterJdbcTemplate jdbc;
    private final PasswordEncoder passwordEncoder;
    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;

    public UserController(CurrentUserService currentUserService, NamedParameterJdbcTemplate jdbc,
                          PasswordEncoder passwordEncoder, AuditLogService auditLogService, ObjectMapper objectMapper) {
        this.currentUserService = currentUserService;
        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    public ApiResponse<?> getUsers(HttpServletRequest request, @RequestParam(required = false, name = "user_id") Integer userId) {
        User currentUser = currentUserService.requireAuth(request);
        if (userId != null) {
            if (!userId.equals(currentUser.getId()) && !(currentUser.getRole() == UserRole.admin || currentUser.getRole() == UserRole.super_admin)) {
                throw new ApiException(HttpStatus.FORBIDDEN, "Admin access required");
            }
            Map<String, Object> user = jdbc.query("SELECT user_id, username, full_name, email, role, is_active, created_at FROM users WHERE user_id = :user_id",
                    Map.of("user_id", userId), rs -> rs.next() ? rowToMap(rs) : null);
            if (user == null) {
                throw new ApiException(HttpStatus.NOT_FOUND, "User not found");
            }
            return ApiResponse.success("User retrieved successfully", user);
        }

        currentUserService.requireAdmin(request);
        List<Map<String, Object>> users = jdbc.queryForList("SELECT user_id, username, full_name, email, role, is_active, created_at FROM users ORDER BY created_at DESC", Map.of());
        return ApiResponse.success("Users retrieved successfully", users);
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createUser(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User currentUser = currentUserService.requireAdmin(request);

        String username = requiredString(payload, "username", "Username, password, full name, and email are required");
        String password = requiredString(payload, "password", "Username, password, full name, and email are required");
        String fullName = requiredString(payload, "full_name", "Username, password, full name, and email are required");
        String email = requiredString(payload, "email", "Username, password, full name, and email are required");
        String role = nullableString(payload.get("role"));
        if (role == null) role = "viewer";
        validateRole(role);
        if (password.length() < 6) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Password must be at least 6 characters long");
        }

        ensureUniqueUsername(username, null);
        ensureUniqueEmail(email, null);

        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        boolean isActive = payload.get("is_active") == null || Boolean.parseBoolean(String.valueOf(payload.get("is_active")));
        jdbc.update("""
                INSERT INTO users (username, password_hash, full_name, email, role, is_active)
                VALUES (:username, :password_hash, :full_name, :email, :role, :is_active)
                """,
                new MapSqlParameterSource()
                        .addValue("username", username)
                        .addValue("password_hash", passwordEncoder.encode(password))
                        .addValue("full_name", fullName)
                        .addValue("email", email)
                        .addValue("role", role)
                        .addValue("is_active", isActive),
                keyHolder,
                new String[]{"user_id"});

        Integer userId = keyHolder.getKey().intValue();
        auditLogService.log(currentUser, "CREATE", "users", userId, null, toJson(payload));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("User created successfully", Map.of(
                        "user_id", userId,
                        "username", username,
                        "full_name", fullName,
                        "email", email,
                        "role", role
                )));
    }

    @PutMapping
    public ApiResponse<Map<String, Integer>> updateUser(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User currentUser = currentUserService.requireAdmin(request);
        Integer userId = toInteger(payload.get("user_id"));
        if (userId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "User ID is required");
        }

        Map<String, Object> oldValues = jdbc.query("SELECT * FROM users WHERE user_id = :user_id",
                Map.of("user_id", userId), rs -> rs.next() ? rowToMap(rs) : null);
        if (oldValues == null) {
            throw new ApiException(HttpStatus.NOT_FOUND, "User not found");
        }

        StringBuilder sql = new StringBuilder("UPDATE users SET ");
        MapSqlParameterSource params = new MapSqlParameterSource().addValue("user_id", userId);
        boolean first = true;

        if (payload.containsKey("username")) {
            String username = nullableString(payload.get("username"));
            ensureUniqueUsername(username, userId);
            sql.append(first ? "" : ", ").append("username = :username");
            params.addValue("username", username);
            first = false;
        }
        if (payload.containsKey("full_name")) {
            sql.append(first ? "" : ", ").append("full_name = :full_name");
            params.addValue("full_name", nullableString(payload.get("full_name")));
            first = false;
        }
        if (payload.containsKey("email")) {
            String email = nullableString(payload.get("email"));
            ensureUniqueEmail(email, userId);
            sql.append(first ? "" : ", ").append("email = :email");
            params.addValue("email", email);
            first = false;
        }
        if (payload.containsKey("role")) {
            String role = nullableString(payload.get("role"));
            validateRole(role);
            sql.append(first ? "" : ", ").append("role = :role");
            params.addValue("role", role);
            first = false;
        }
        if (payload.containsKey("is_active")) {
            sql.append(first ? "" : ", ").append("is_active = :is_active");
            params.addValue("is_active", Boolean.parseBoolean(String.valueOf(payload.get("is_active"))));
            first = false;
        }
        if (payload.containsKey("password") && nullableString(payload.get("password")) != null) {
            String password = nullableString(payload.get("password"));
            if (password.length() < 6) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Password must be at least 6 characters long");
            }
            sql.append(first ? "" : ", ").append("password_hash = :password_hash");
            params.addValue("password_hash", passwordEncoder.encode(password));
            first = false;
        }

        if (first) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "No fields to update");
        }

        sql.append(" WHERE user_id = :user_id");
        int updated = jdbc.update(sql.toString(), params);
        if (updated == 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Failed to update user or no changes made");
        }
        auditLogService.log(currentUser, "UPDATE", "users", userId, toJson(oldValues), toJson(payload));
        return ApiResponse.success("User updated successfully", Map.of("user_id", userId));
    }

    @DeleteMapping
    public ApiResponse<Map<String, Integer>> deactivateUser(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        User currentUser = currentUserService.requireAdmin(request);
        Integer userId = toInteger(payload.get("user_id"));
        if (userId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "User ID is required");
        }
        if (userId.equals(currentUser.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Cannot delete your own account");
        }
        int updated = jdbc.update("UPDATE users SET is_active = FALSE WHERE user_id = :user_id", Map.of("user_id", userId));
        if (updated == 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Failed to deactivate user or user not found");
        }
        auditLogService.log(currentUser, "DEACTIVATE", "users", userId);
        return ApiResponse.success("User deactivated successfully", Map.of("user_id", userId));
    }

    private void ensureUniqueUsername(String username, Integer userId) {
        if (username == null) return;
        String sql = userId == null
                ? "SELECT COUNT(*) FROM users WHERE username = :username"
                : "SELECT COUNT(*) FROM users WHERE username = :username AND user_id != :user_id";
        Map<String, Object> params = userId == null ? Map.of("username", username) : Map.of("username", username, "user_id", userId);
        Integer count = jdbc.queryForObject(sql, params, Integer.class);
        if (count != null && count > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Username already exists");
        }
    }

    private void ensureUniqueEmail(String email, Integer userId) {
        if (email == null) return;
        String sql = userId == null
                ? "SELECT COUNT(*) FROM users WHERE email = :email"
                : "SELECT COUNT(*) FROM users WHERE email = :email AND user_id != :user_id";
        Map<String, Object> params = userId == null ? Map.of("email", email) : Map.of("email", email, "user_id", userId);
        Integer count = jdbc.queryForObject(sql, params, Integer.class);
        if (count != null && count > 0) {
            throw new ApiException(HttpStatus.CONFLICT, "Email already exists");
        }
    }

    private void validateRole(String role) {
        if (role == null || !(role.equals("super_admin") || role.equals("admin") || role.equals("staff") || role.equals("viewer"))) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid role. Must be: super_admin, admin, staff, or viewer");
        }
    }

    private String requiredString(Map<String, Object> payload, String key, String message) {
        String value = nullableString(payload.get(key));
        if (value == null) throw new ApiException(HttpStatus.BAD_REQUEST, message);
        return value;
    }

    private String nullableString(Object value) {
        if (value == null) return null;
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? null : text;
    }

    private Integer toInteger(Object value) {
        if (value == null || String.valueOf(value).isBlank()) return null;
        return Integer.valueOf(String.valueOf(value));
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
