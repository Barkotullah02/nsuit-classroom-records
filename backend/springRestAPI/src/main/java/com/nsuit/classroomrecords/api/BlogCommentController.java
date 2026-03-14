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
@RequestMapping("/api/blog-comments")
public class BlogCommentController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public BlogCommentController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    private String s(Map<String, Object> m, String k) {
        Object v = m.get(k); return v == null ? null : v.toString();
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getComments(
            @RequestParam(required = false) Long post_id,
            HttpServletRequest request) {
        // Public endpoint
        if (post_id == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Post ID is required");

        List<Map<String, Object>> all = jdbc.queryForList(
                "SELECT c.*, u.full_name as user_name, u.username, " +
                "(SELECT COUNT(*) FROM blog_comments WHERE parent_comment_id = c.comment_id AND is_deleted = FALSE) as reply_count " +
                "FROM blog_comments c JOIN users u ON c.user_id = u.user_id " +
                "WHERE c.post_id = :post_id AND c.is_deleted = FALSE ORDER BY c.created_at ASC",
                new MapSqlParameterSource("post_id", post_id));

        // Organise into threads
        Map<Object, Map<String, Object>> topLevel = new LinkedHashMap<>();
        Map<Object, List<Map<String, Object>>> replies = new LinkedHashMap<>();

        for (Map<String, Object> c : all) {
            if (c.get("parent_comment_id") == null) {
                c.put("replies", new ArrayList<>());
                topLevel.put(c.get("comment_id"), c);
            } else {
                Object parentId = c.get("parent_comment_id");
                replies.computeIfAbsent(parentId, k -> new ArrayList<>()).add(c);
            }
        }
        for (Map.Entry<Object, List<Map<String, Object>>> e : replies.entrySet()) {
            Map<String, Object> parent = topLevel.get(e.getKey());
            if (parent != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> list = (List<Map<String, Object>>) parent.get("replies");
                list.addAll(e.getValue());
            }
        }
        return ApiResponse.success("Comments retrieved successfully", new ArrayList<>(topLevel.values()));
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> addComment(@RequestBody Map<String, Object> data,
                                                        HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        if (data.get("post_id") == null || s(data, "comment_text") == null || s(data, "comment_text").isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Post ID and comment text are required");
        }

        Object parentId = data.get("parent_comment_id");
        KeyHolder kh = new GeneratedKeyHolder();
        jdbc.update("INSERT INTO blog_comments (post_id, user_id, parent_comment_id, comment_text) " +
                "VALUES (:post_id, :user_id, :parent_comment_id, :comment_text)",
                new MapSqlParameterSource()
                        .addValue("post_id", Long.parseLong(data.get("post_id").toString()))
                        .addValue("user_id", user.getId())
                        .addValue("parent_comment_id", parentId != null ? Long.parseLong(parentId.toString()) : null)
                        .addValue("comment_text", s(data, "comment_text")),
                kh);
        return ApiResponse.success("Comment posted successfully", Map.of("comment_id", kh.getKey().longValue()));
    }

    @PutMapping
    public ApiResponse<Map<String, Object>> updateComment(@RequestBody Map<String, Object> data,
                                                           HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        if (data.get("comment_id") == null || s(data, "comment_text") == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Comment ID and text are required");
        }
        long commentId = Long.parseLong(data.get("comment_id").toString());

        List<Map<String, Object>> existing = jdbc.queryForList(
                "SELECT user_id FROM blog_comments WHERE comment_id = :id",
                new MapSqlParameterSource("id", commentId));
        if (existing.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "Comment not found");

        Object ownerId = existing.get(0).get("user_id");
        boolean isAdmin = user.getRole() == UserRole.admin || user.getRole() == UserRole.super_admin;
        if (!isAdmin && !ownerId.toString().equals(String.valueOf(user.getId()))) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Unauthorized");
        }

        jdbc.update("UPDATE blog_comments SET comment_text = :text WHERE comment_id = :id",
                new MapSqlParameterSource("text", s(data, "comment_text")).addValue("id", commentId));
        return ApiResponse.success("Comment updated successfully", Map.of("comment_id", commentId));
    }

    @DeleteMapping
    public ApiResponse<Map<String, Object>> deleteComment(@RequestBody Map<String, Object> body,
                                                           HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        if (body.get("comment_id") == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Comment ID is required");
        long commentId = Long.parseLong(body.get("comment_id").toString());

        List<Map<String, Object>> existing = jdbc.queryForList(
                "SELECT user_id FROM blog_comments WHERE comment_id = :id",
                new MapSqlParameterSource("id", commentId));
        if (existing.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "Comment not found");

        Object ownerId = existing.get(0).get("user_id");
        boolean isAdmin = user.getRole() == UserRole.admin || user.getRole() == UserRole.super_admin;
        if (!isAdmin && !ownerId.toString().equals(String.valueOf(user.getId()))) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Unauthorized");
        }

        jdbc.update("UPDATE blog_comments SET is_deleted = TRUE WHERE comment_id = :id",
                new MapSqlParameterSource("id", commentId));
        return ApiResponse.success("Comment deleted successfully", Map.of("comment_id", commentId));
    }
}
