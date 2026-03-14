package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.common.exception.ApiException;
import com.nsuit.classroomrecords.model.User;
import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/blog-reactions")
public class BlogReactionController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public BlogReactionController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    private String s(Map<String, Object> m, String k) {
        Object v = m.get(k); return v == null ? null : v.toString();
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> getReactions(
            @RequestParam(required = false) Long post_id,
            HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        if (post_id == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Post ID is required");

        List<Map<String, Object>> reactions = jdbc.queryForList(
                "SELECT reaction_type, COUNT(*) as count FROM blog_reactions " +
                "WHERE post_id = :post_id GROUP BY reaction_type",
                new MapSqlParameterSource("post_id", post_id));

        List<Map<String, Object>> userRxn = jdbc.queryForList(
                "SELECT reaction_type FROM blog_reactions WHERE post_id = :post_id AND user_id = :user_id",
                new MapSqlParameterSource("post_id", post_id).addValue("user_id", user.getId()));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("reactions", reactions);
        data.put("user_reaction", userRxn.isEmpty() ? null : userRxn.get(0).get("reaction_type"));
        return ApiResponse.success("Reactions retrieved successfully", data);
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> saveReaction(@RequestBody Map<String, Object> body,
                                                          HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        if (body.get("post_id") == null || s(body, "reaction_type") == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Post ID and reaction type are required");
        }
        String reactionType = s(body, "reaction_type");
        if (!List.of("like", "love", "celebrate", "insightful").contains(reactionType)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid reaction type");
        }

        long postId = Long.parseLong(body.get("post_id").toString());

        Long existing = jdbc.queryForObject(
                "SELECT COUNT(*) FROM blog_reactions WHERE post_id = :post_id AND user_id = :user_id",
                new MapSqlParameterSource("post_id", postId).addValue("user_id", user.getId()), Long.class);

        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("post_id", postId)
                .addValue("user_id", user.getId())
                .addValue("reaction_type", reactionType);

        if (existing != null && existing > 0) {
            jdbc.update("UPDATE blog_reactions SET reaction_type = :reaction_type " +
                    "WHERE post_id = :post_id AND user_id = :user_id", params);
        } else {
            jdbc.update("INSERT INTO blog_reactions (post_id, user_id, reaction_type) " +
                    "VALUES (:post_id, :user_id, :reaction_type)", params);
        }
        return ApiResponse.success("Reaction saved successfully", Map.of("reaction_type", reactionType));
    }

    @DeleteMapping
    public ApiResponse<Object> removeReaction(@RequestBody Map<String, Object> body,
                                               HttpServletRequest request) {
        User user = currentUserService.requireAuth(request);

        if (body.get("post_id") == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Post ID is required");
        long postId = Long.parseLong(body.get("post_id").toString());

        jdbc.update("DELETE FROM blog_reactions WHERE post_id = :post_id AND user_id = :user_id",
                new MapSqlParameterSource("post_id", postId).addValue("user_id", user.getId()));
        return ApiResponse.success("Reaction removed successfully", null);
    }
}
