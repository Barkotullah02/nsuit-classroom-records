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

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@RequestMapping("/api/blog-posts")
public class BlogPostController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public BlogPostController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    private String s(Map<String, Object> m, String k) {
        Object v = m.get(k); return v == null ? null : v.toString();
    }

    @GetMapping
    public ApiResponse<?> getPosts(
            @RequestParam(required = false) Long post_id,
            @RequestParam(required = false) String slug,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "published") String status,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(defaultValue = "false") boolean popular,
            HttpServletRequest request) {
        // Public endpoint — no auth needed

        String postFields = "p.*, c.category_name, c.category_slug, u.full_name as author_name, " +
                "(SELECT COUNT(*) FROM blog_comments WHERE post_id = p.post_id AND is_deleted = FALSE) as comment_count, " +
                "(SELECT COUNT(*) FROM blog_reactions WHERE post_id = p.post_id) as reaction_count";

        if (post_id != null) {
            List<Map<String, Object>> rows = jdbc.queryForList(
                    "SELECT " + postFields + " FROM blog_posts p " +
                    "LEFT JOIN blog_categories c ON p.category_id = c.category_id " +
                    "LEFT JOIN users u ON p.author_id = u.user_id " +
                    "WHERE p.post_id = :id",
                    new MapSqlParameterSource("id", post_id));
            if (rows.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "Post not found");
            jdbc.update("UPDATE blog_posts SET view_count = view_count + 1 WHERE post_id = :id",
                    new MapSqlParameterSource("id", post_id));
            return ApiResponse.success("Post retrieved successfully", rows.get(0));
        }
        if (slug != null && !slug.isBlank()) {
            List<Map<String, Object>> rows = jdbc.queryForList(
                    "SELECT " + postFields + " FROM blog_posts p " +
                    "LEFT JOIN blog_categories c ON p.category_id = c.category_id " +
                    "LEFT JOIN users u ON p.author_id = u.user_id " +
                    "WHERE p.slug = :slug AND p.status = 'published'",
                    new MapSqlParameterSource("slug", slug));
            if (rows.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "Post not found");
            jdbc.update("UPDATE blog_posts SET view_count = view_count + 1 WHERE post_id = :id",
                    new MapSqlParameterSource("id", rows.get(0).get("post_id")));
            return ApiResponse.success("Post retrieved successfully", rows.get(0));
        }

        // List
        List<String> whereClauses = new ArrayList<>();
        MapSqlParameterSource params = new MapSqlParameterSource();

        if (status != null && !"all".equals(status)) {
            whereClauses.add("p.status = :status");
            params.addValue("status", status);
        }
        if (category != null && !category.isBlank()) {
            whereClauses.add("c.category_slug = :category");
            params.addValue("category", category);
        }
        if (search != null && !search.isBlank()) {
            whereClauses.add("(p.title LIKE :search OR p.content LIKE :search OR p.excerpt LIKE :search)");
            params.addValue("search", "%" + search + "%");
        }
        String whereSql = whereClauses.isEmpty() ? "" : "WHERE " + String.join(" AND ", whereClauses);
        String orderBy = popular ? "ORDER BY p.view_count DESC, p.published_at DESC"
                                 : "ORDER BY p.is_pinned DESC, p.published_at DESC";

        String listFields = "p.post_id, p.title, p.slug, p.excerpt, p.featured_image, " +
                "p.status, p.view_count, p.is_pinned, p.published_at, p.created_at, " +
                "c.category_name, c.category_slug, u.full_name as author_name, " +
                "(SELECT COUNT(*) FROM blog_comments WHERE post_id = p.post_id AND is_deleted = FALSE) as comment_count, " +
                "(SELECT COUNT(*) FROM blog_reactions WHERE post_id = p.post_id) as reaction_count";

        params.addValue("limit", limit);
        params.addValue("offset_val", offset);
        List<Map<String, Object>> posts = jdbc.queryForList(
                "SELECT " + listFields + " FROM blog_posts p " +
                "LEFT JOIN blog_categories c ON p.category_id = c.category_id " +
                "LEFT JOIN users u ON p.author_id = u.user_id " +
                whereSql + " " + orderBy + " LIMIT :limit OFFSET :offset_val",
                params);

        // Build count params from the same filter clauses, no limit/offset
        MapSqlParameterSource countParams = new MapSqlParameterSource();
        if (status != null && !"all".equals(status)) countParams.addValue("status", status);
        if (category != null && !category.isBlank()) countParams.addValue("category", category);
        if (search != null && !search.isBlank()) countParams.addValue("search", "%" + search + "%");

        Long total = jdbc.queryForObject(
                "SELECT COUNT(*) FROM blog_posts p " +
                "LEFT JOIN blog_categories c ON p.category_id = c.category_id " +
                whereSql,
                countParams, Long.class);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("posts", posts);
        data.put("total", total);
        data.put("limit", limit);
        data.put("offset", offset);
        return ApiResponse.success("Posts retrieved successfully", data);
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> createPost(@RequestBody Map<String, Object> data,
                                                        HttpServletRequest request) {
        User user = currentUserService.requireAdmin(request);

        if (s(data, "title") == null || s(data, "content") == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Title and content are required");
        }

        // Generate slug
        String slug = s(data, "title").toLowerCase().trim()
                .replaceAll("[^a-z0-9-]+", "-").replaceAll("-+", "-").replaceAll("^-|-$", "");
        Long exists = jdbc.queryForObject("SELECT COUNT(*) FROM blog_posts WHERE slug = :slug",
                new MapSqlParameterSource("slug", slug), Long.class);
        if (exists != null && exists > 0) slug += "-" + System.currentTimeMillis();

        String status = s(data, "status") != null ? s(data, "status") : "draft";
        String publishedAt = "published".equals(status)
                ? LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) : null;

        KeyHolder kh = new GeneratedKeyHolder();
        jdbc.update("INSERT INTO blog_posts (title, slug, content, excerpt, category_id, author_id, " +
                "featured_image, status, published_at) VALUES " +
                "(:title, :slug, :content, :excerpt, :category_id, :author_id, :featured_image, :status, :published_at)",
                new MapSqlParameterSource()
                        .addValue("title", s(data, "title"))
                        .addValue("slug", slug)
                        .addValue("content", s(data, "content"))
                        .addValue("excerpt", s(data, "excerpt"))
                        .addValue("category_id", data.get("category_id") != null ? Long.parseLong(data.get("category_id").toString()) : null)
                        .addValue("author_id", user.getId())
                        .addValue("featured_image", s(data, "featured_image"))
                        .addValue("status", status)
                        .addValue("published_at", publishedAt),
                kh);
        return ApiResponse.success("Post created successfully", Map.<String, Object>of("post_id", kh.getKey().longValue(), "slug", slug));
    }

    @PutMapping
    public ApiResponse<Map<String, Object>> updatePost(@RequestBody Map<String, Object> data,
                                                        HttpServletRequest request) {
        currentUserService.requireAdmin(request);

        if (data.get("post_id") == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Post ID is required");
        long postId = Long.parseLong(data.get("post_id").toString());

        StringBuilder updates = new StringBuilder();
        MapSqlParameterSource params = new MapSqlParameterSource("post_id", postId);

        if (data.containsKey("title")) { updates.append("title = :title, "); params.addValue("title", s(data, "title")); }
        if (data.containsKey("content")) { updates.append("content = :content, "); params.addValue("content", s(data, "content")); }
        if (data.containsKey("excerpt")) { updates.append("excerpt = :excerpt, "); params.addValue("excerpt", s(data, "excerpt")); }
        if (data.containsKey("category_id")) {
            updates.append("category_id = :category_id, ");
            params.addValue("category_id", data.get("category_id") != null ? Long.parseLong(data.get("category_id").toString()) : null);
        }
        if (data.containsKey("featured_image")) { updates.append("featured_image = :featured_image, "); params.addValue("featured_image", s(data, "featured_image")); }
        if (data.containsKey("status")) {
            updates.append("status = :status, "); params.addValue("status", s(data, "status"));
            if ("published".equals(s(data, "status"))) updates.append("published_at = NOW(), ");
        }
        if (data.containsKey("is_pinned")) {
            updates.append("is_pinned = :is_pinned, ");
            params.addValue("is_pinned", Boolean.TRUE.equals(data.get("is_pinned")) ? 1 : 0);
        }
        if (updates.length() == 0) throw new ApiException(HttpStatus.BAD_REQUEST, "No fields to update");

        String updateSql = updates.toString().replaceAll(", $", "");
        int updated = jdbc.update("UPDATE blog_posts SET " + updateSql + " WHERE post_id = :post_id", params);
        if (updated == 0) throw new ApiException(HttpStatus.NOT_FOUND, "Post not found");
        return ApiResponse.success("Post updated successfully", Map.of("post_id", postId));
    }

    @DeleteMapping
    public ApiResponse<Object> deletePost(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        currentUserService.requireAdmin(request);

        if (body.get("post_id") == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Post ID is required");
        long postId = Long.parseLong(body.get("post_id").toString());

        int deleted = jdbc.update("DELETE FROM blog_posts WHERE post_id = :id",
                new MapSqlParameterSource("id", postId));
        if (deleted == 0) throw new ApiException(HttpStatus.NOT_FOUND, "Post not found");
        return ApiResponse.success("Post deleted successfully", Map.of("post_id", postId));
    }
}
