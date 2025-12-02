<?php
/**
 * Blog Categories API
 * Manage blog categories
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/response.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Public endpoint - get all categories
    try {
        $query = "SELECT c.*, 
                        (SELECT COUNT(*) FROM blog_posts WHERE category_id = c.category_id AND status = 'published') as post_count
                 FROM blog_categories c
                 ORDER BY c.category_name";
        
        $stmt = $db->query($query);
        $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        Response::success($categories, 'Categories retrieved successfully');
    } catch (Exception $e) {
        Response::error('Failed to retrieve categories: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
