package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.model.enums.UserRole;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/classroom-support")
public class ClassroomSupportController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public ClassroomSupportController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    private String s(Map<String, Object> m, String k) {
        Object v = m.get(k); return v == null ? null : v.toString();
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getRecords(
            @RequestParam(required = false) Long member_id,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String date_from,
            @RequestParam(required = false) String date_to,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String issue_type,
            HttpServletRequest request) {
        currentUserService.requireAuth(request);

        StringBuilder where = new StringBuilder("WHERE csr.is_deleted = FALSE");
        MapSqlParameterSource params = new MapSqlParameterSource();

        if (member_id != null) { where.append(" AND csr.member_id = :member_id"); params.addValue("member_id", member_id); }
        if (location != null && !location.isBlank()) { where.append(" AND csr.location LIKE :location"); params.addValue("location", "%" + location + "%"); }
        if (date_from != null && !date_from.isBlank()) { where.append(" AND csr.support_date >= :date_from"); params.addValue("date_from", date_from); }
        if (date_to   != null && !date_to.isBlank())   { where.append(" AND csr.support_date <= :date_to");   params.addValue("date_to",   date_to); }
        if (status != null && !status.isBlank()) { where.append(" AND csr.status = :status"); params.addValue("status", status); }
        if (issue_type != null && !issue_type.isBlank()) { where.append(" AND csr.issue_type = :issue_type"); params.addValue("issue_type", issue_type); }

        List<Map<String, Object>> records = jdbc.queryForList(
                "SELECT csr.support_id, csr.member_id, stm.member_name, stm.department, " +
                "csr.support_date, csr.support_time, " +
                "CONCAT(csr.support_date, ' ', csr.support_time) as support_datetime, " +
                "csr.location, csr.room_id, r.room_name, r.building, " +
                "csr.support_description, csr.issue_type, csr.priority, csr.status, " +
                "csr.devices_involved, csr.duration_minutes, csr.faculty_name, csr.notes, " +
                "csr.created_by, u.full_name as created_by_name, csr.created_at, csr.updated_at " +
                "FROM classroom_support_records csr " +
                "JOIN support_team_members stm ON csr.member_id = stm.member_id " +
                "LEFT JOIN rooms r ON csr.room_id = r.room_id " +
                "LEFT JOIN users u ON csr.created_by = u.user_id " +
                where + " ORDER BY csr.support_date DESC, csr.support_time DESC",
                params);
        return ApiResponse.success("Support records retrieved successfully", records);
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> createRecord(@RequestBody Map<String, Object> data,
                                                          HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        List<String> required = List.of("member_id", "support_date", "support_time", "location", "support_description");
        Map<String, String> errors = new LinkedHashMap<>();
        for (String f : required) {
            if (data.get(f) == null || data.get(f).toString().isBlank())
                errors.put(f, f.replace("_", " ") + " is required");
        }
        if (!errors.isEmpty()) throw new ApiException(HttpStatus.BAD_REQUEST, "Validation failed", errors);

        KeyHolder kh = new GeneratedKeyHolder();
        jdbc.update("INSERT INTO classroom_support_records " +
                "(member_id, support_date, support_time, location, room_id, support_description, " +
                "issue_type, priority, status, devices_involved, duration_minutes, faculty_name, notes, created_by) " +
                "VALUES " +
                "(:member_id, :support_date, :support_time, :location, :room_id, :support_description, " +
                ":issue_type, :priority, :status, :devices_involved, :duration_minutes, :faculty_name, :notes, :created_by)",
                new MapSqlParameterSource()
                        .addValue("member_id", Long.parseLong(data.get("member_id").toString()))
                        .addValue("support_date", s(data, "support_date"))
                        .addValue("support_time", s(data, "support_time"))
                        .addValue("location", s(data, "location"))
                        .addValue("room_id", data.get("room_id") != null ? Long.parseLong(data.get("room_id").toString()) : null)
                        .addValue("support_description", s(data, "support_description"))
                        .addValue("issue_type", s(data, "issue_type"))
                        .addValue("priority", s(data, "priority"))
                        .addValue("status", s(data, "status"))
                        .addValue("devices_involved", s(data, "devices_involved"))
                        .addValue("duration_minutes", data.get("duration_minutes") != null ? Integer.parseInt(data.get("duration_minutes").toString()) : null)
                        .addValue("faculty_name", s(data, "faculty_name"))
                        .addValue("notes", s(data, "notes"))
                        .addValue("created_by", user.getId()),
                kh);
        return ApiResponse.success("Support record created successfully", Map.of("support_id", kh.getKey().longValue()));
    }

    @PutMapping
    public ApiResponse<Object> updateRecord(@RequestBody Map<String, Object> data,
                                             HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        if (data.get("support_id") == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Support ID is required");
        long supportId = Long.parseLong(data.get("support_id").toString());

        boolean isAdmin = user.getRole() == UserRole.admin || user.getRole() == UserRole.super_admin;

        List<Map<String, Object>> existing = jdbc.queryForList(
                "SELECT created_by FROM classroom_support_records WHERE support_id = :id",
                new MapSqlParameterSource("id", supportId));
        if (existing.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "Support record not found");

        Object createdBy = existing.get(0).get("created_by");
        if (!isAdmin && (createdBy == null || !createdBy.toString().equals(String.valueOf(user.getId())))) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Unauthorized. You can only edit your own records.");
        }

        jdbc.update("UPDATE classroom_support_records SET " +
                "member_id = :member_id, support_date = :support_date, support_time = :support_time, " +
                "location = :location, room_id = :room_id, support_description = :support_description, " +
                "issue_type = :issue_type, priority = :priority, status = :status, " +
                "devices_involved = :devices_involved, duration_minutes = :duration_minutes, " +
                "faculty_name = :faculty_name, notes = :notes " +
                "WHERE support_id = :support_id",
                new MapSqlParameterSource()
                        .addValue("support_id", supportId)
                        .addValue("member_id", data.get("member_id") != null ? Long.parseLong(data.get("member_id").toString()) : null)
                        .addValue("support_date", s(data, "support_date"))
                        .addValue("support_time", s(data, "support_time"))
                        .addValue("location", s(data, "location"))
                        .addValue("room_id", data.get("room_id") != null ? Long.parseLong(data.get("room_id").toString()) : null)
                        .addValue("support_description", s(data, "support_description"))
                        .addValue("issue_type", s(data, "issue_type"))
                        .addValue("priority", s(data, "priority"))
                        .addValue("status", s(data, "status"))
                        .addValue("devices_involved", s(data, "devices_involved"))
                        .addValue("duration_minutes", data.get("duration_minutes") != null ? Integer.parseInt(data.get("duration_minutes").toString()) : null)
                        .addValue("faculty_name", s(data, "faculty_name"))
                        .addValue("notes", s(data, "notes")));
        return ApiResponse.success("Support record updated successfully", null);
    }

    @DeleteMapping
    public ApiResponse<Object> deleteRecord(@RequestParam long support_id, HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        boolean isAdmin = user.getRole() == UserRole.admin || user.getRole() == UserRole.super_admin;

        List<Map<String, Object>> existing = jdbc.queryForList(
                "SELECT created_by FROM classroom_support_records WHERE support_id = :id",
                new MapSqlParameterSource("id", support_id));
        if (existing.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "Support record not found");

        Object createdBy = existing.get(0).get("created_by");
        if (!isAdmin && (createdBy == null || !createdBy.toString().equals(String.valueOf(user.getId())))) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Unauthorized. You can only delete your own records.");
        }

        jdbc.update("UPDATE classroom_support_records " +
                "SET is_deleted = TRUE, deleted_at = NOW(), deleted_by = :uid WHERE support_id = :id",
                new MapSqlParameterSource("uid", user.getId()).addValue("id", support_id));
        return ApiResponse.success("Support record deleted successfully", null);
    }
}
