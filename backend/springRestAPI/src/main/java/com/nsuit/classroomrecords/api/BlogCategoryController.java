package com.nsuit.classroomrecords.api;

import com.nsuit.classroomrecords.service.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/blog-categories")
public class BlogCategoryController {

    private final NamedParameterJdbcTemplate jdbc;
    private final CurrentUserService currentUserService;

    public BlogCategoryController(NamedParameterJdbcTemplate jdbc, CurrentUserService currentUserService) {
        this.jdbc = jdbc;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> getCategories(HttpServletRequest request) {
        // Public endpoint — no auth required
        List<Map<String, Object>> categories = jdbc.queryForList(
                "SELECT c.*, " +
                "(SELECT COUNT(*) FROM blog_posts WHERE category_id = c.category_id AND status = 'published') as post_count " +
                "FROM blog_categories c ORDER BY c.category_name",
                Map.of());
        return ApiResponse.success("Categories retrieved successfully", categories);
    }
}
