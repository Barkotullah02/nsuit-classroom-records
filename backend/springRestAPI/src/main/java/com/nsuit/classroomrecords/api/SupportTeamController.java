package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
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
@RequestMapping("/api/support-team")
public class SupportTeamController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public SupportTeamController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    private String s(Map<String, Object> m, String k) {
        Object v = m.get(k); return v == null ? null : v.toString();
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getMembers(
            @RequestParam(required = false) String is_active,
            HttpServletRequest request) {
        currentUserService.requireAuth(request);

        StringBuilder where = new StringBuilder("WHERE 1=1");
        MapSqlParameterSource params = new MapSqlParameterSource();
        if (is_active != null) {
            where.append(" AND is_active = :is_active");
            params.addValue("is_active", is_active);
        }

        List<Map<String, Object>> members = jdbc.queryForList(
                "SELECT stm.member_id, stm.user_id, stm.member_name, stm.member_email, " +
                "stm.member_phone, stm.department, stm.is_active, stm.created_at, " +
                "u.full_name as created_by_name " +
                "FROM support_team_members stm " +
                "LEFT JOIN users u ON stm.created_by = u.user_id " +
                where + " ORDER BY stm.member_name",
                params);
        return ApiResponse.success("Support team members retrieved successfully", members);
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> createMember(@RequestBody Map<String, Object> data,
                                                          HttpServletRequest request) {
        User user = currentUserService.requireAdmin(request);

        if (s(data, "member_name") == null || s(data, "member_name").isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Member name is required");
        }

        KeyHolder kh = new GeneratedKeyHolder();
        jdbc.update("INSERT INTO support_team_members " +
                "(member_name, member_email, member_phone, department, user_id, created_by) " +
                "VALUES (:member_name, :member_email, :member_phone, :department, :user_id, :created_by)",
                new MapSqlParameterSource()
                        .addValue("member_name", s(data, "member_name"))
                        .addValue("member_email", s(data, "member_email"))
                        .addValue("member_phone", s(data, "member_phone"))
                        .addValue("department", s(data, "department"))
                        .addValue("user_id", data.get("user_id"))
                        .addValue("created_by", user.getId()),
                kh);
        return ApiResponse.success("Support team member added successfully", Map.<String, Object>of("member_id", kh.getKey().longValue()));
    }

    @PutMapping
    public ApiResponse<Object> updateMember(@RequestBody Map<String, Object> data,
                                             HttpServletRequest request) {
        currentUserService.requireAdmin(request);

        if (data.get("member_id") == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Member ID is required");

        Object isActive = data.get("is_active");
        jdbc.update("UPDATE support_team_members SET " +
                "member_name = :member_name, member_email = :member_email, member_phone = :member_phone, " +
                "department = :department, user_id = :user_id, is_active = :is_active " +
                "WHERE member_id = :member_id",
                new MapSqlParameterSource()
                        .addValue("member_id", Long.parseLong(data.get("member_id").toString()))
                        .addValue("member_name", s(data, "member_name"))
                        .addValue("member_email", s(data, "member_email"))
                        .addValue("member_phone", s(data, "member_phone"))
                        .addValue("department", s(data, "department"))
                        .addValue("user_id", data.get("user_id"))
                        .addValue("is_active", isActive));
        return ApiResponse.success("Support team member updated successfully", null);
    }

    @DeleteMapping
    public ApiResponse<Object> deleteMember(@RequestParam long member_id, HttpServletRequest request) {
        currentUserService.requireAdmin(request);

        Long count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM classroom_support_records WHERE member_id = :mid AND is_deleted = FALSE",
                new MapSqlParameterSource("mid", member_id), Long.class);
        if (count != null && count > 0) {
            throw new ApiException(HttpStatus.CONFLICT,
                    "Cannot delete member with existing support records. Set to inactive instead.");
        }

        jdbc.update("DELETE FROM support_team_members WHERE member_id = :mid",
                new MapSqlParameterSource("mid", member_id));
        return ApiResponse.success("Support team member deleted successfully", null);
    }
}
