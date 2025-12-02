<?php
/**
 * Blog Posts API
 * Manage blog posts - CRUD operations
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Public endpoint - no auth required for reading
    try {
        $post_id = $_GET['post_id'] ?? null;
        $slug = $_GET['slug'] ?? null;
        $category = $_GET['category'] ?? null;
        $status = $_GET['status'] ?? 'published';
        $search = $_GET['search'] ?? null;
        $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
        $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
        $popular = $_GET['popular'] ?? false;

        if ($post_id) {
            // Get single post by ID
            $query = "SELECT p.*, c.category_name, c.category_slug,
                            u.full_name as author_name,
                            (SELECT COUNT(*) FROM blog_comments WHERE post_id = p.post_id AND is_deleted = FALSE) as comment_count,
                            (SELECT COUNT(*) FROM blog_reactions WHERE post_id = p.post_id) as reaction_count
                     FROM blog_posts p
                     LEFT JOIN blog_categories c ON p.category_id = c.category_id
                     LEFT JOIN users u ON p.author_id = u.user_id
                     WHERE p.post_id = :post_id";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':post_id', $post_id);
            $stmt->execute();
            $post = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($post) {
                // Increment view count
                $update = "UPDATE blog_posts SET view_count = view_count + 1 WHERE post_id = :post_id";
                $update_stmt = $db->prepare($update);
                $update_stmt->bindParam(':post_id', $post_id);
                $update_stmt->execute();
                
                Response::success($post, 'Post retrieved successfully');
            } else {
                Response::error('Post not found', 404);
            }
        } elseif ($slug) {
            // Get single post by slug
            $query = "SELECT p.*, c.category_name, c.category_slug,
                            u.full_name as author_name,
                            (SELECT COUNT(*) FROM blog_comments WHERE post_id = p.post_id AND is_deleted = FALSE) as comment_count,
                            (SELECT COUNT(*) FROM blog_reactions WHERE post_id = p.post_id) as reaction_count
                     FROM blog_posts p
                     LEFT JOIN blog_categories c ON p.category_id = c.category_id
                     LEFT JOIN users u ON p.author_id = u.user_id
                     WHERE p.slug = :slug AND p.status = 'published'";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':slug', $slug);
            $stmt->execute();
            $post = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($post) {
                // Increment view count
                $update = "UPDATE blog_posts SET view_count = view_count + 1 WHERE post_id = :post_id";
                $update_stmt = $db->prepare($update);
                $update_stmt->bindParam(':post_id', $post['post_id']);
                $update_stmt->execute();
                
                Response::success($post, 'Post retrieved successfully');
            } else {
                Response::error('Post not found', 404);
            }
        } else {
            // Get list of posts
            $where_clauses = [];
            $params = [];
            
            if ($status && $status !== 'all') {
                $where_clauses[] = "p.status = :status";
                $params[':status'] = $status;
            }
            
            if ($category) {
                $where_clauses[] = "c.category_slug = :category";
                $params[':category'] = $category;
            }
            
            if ($search) {
                $where_clauses[] = "(p.title LIKE :search OR p.content LIKE :search OR p.excerpt LIKE :search)";
                $params[':search'] = '%' . $search . '%';
            }
            
            $where_sql = $where_clauses ? 'WHERE ' . implode(' AND ', $where_clauses) : '';
            
            $order_by = $popular ? 'ORDER BY p.view_count DESC, p.published_at DESC' : 'ORDER BY p.is_pinned DESC, p.published_at DESC';
            
            $query = "SELECT p.post_id, p.title, p.slug, p.excerpt, p.featured_image, 
                            p.status, p.view_count, p.is_pinned, p.published_at, p.created_at,
                            c.category_name, c.category_slug,
                            u.full_name as author_name,
                            (SELECT COUNT(*) FROM blog_comments WHERE post_id = p.post_id AND is_deleted = FALSE) as comment_count,
                            (SELECT COUNT(*) FROM blog_reactions WHERE post_id = p.post_id) as reaction_count
                     FROM blog_posts p
                     LEFT JOIN blog_categories c ON p.category_id = c.category_id
                     LEFT JOIN users u ON p.author_id = u.user_id
                     $where_sql
                     $order_by
                     LIMIT :limit OFFSET :offset";
            
            $stmt = $db->prepare($query);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
            $stmt->execute();
            
            $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get total count
            $count_query = "SELECT COUNT(*) as total 
                           FROM blog_posts p
                           LEFT JOIN blog_categories c ON p.category_id = c.category_id
                           $where_sql";
            $count_stmt = $db->prepare($count_query);
            foreach ($params as $key => $value) {
                $count_stmt->bindValue($key, $value);
            }
            $count_stmt->execute();
            $total = $count_stmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            Response::success([
                'posts' => $posts,
                'total' => $total,
                'limit' => $limit,
                'offset' => $offset
            ], 'Posts retrieved successfully');
        }
    } catch (Exception $e) {
        Response::error('Failed to retrieve posts: ' . $e->getMessage());
    }
} elseif ($method === 'POST') {
    // Create new post - Admin only
    $auth = new Auth();
    $auth->requireAuth();
    $user = $auth->getCurrentUser();
    
    if ($user['role'] !== 'admin') {
        Response::error('Unauthorized. Admin access required.', 403);
    }
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['title']) || empty($data['content'])) {
            Response::error('Title and content are required');
        }
        
        // Generate slug from title
        $slug = strtolower(trim(preg_replace('/[^A-Za-z0-9-]+/', '-', $data['title'])));
        
        // Check if slug exists
        $check = "SELECT post_id FROM blog_posts WHERE slug = :slug";
        $check_stmt = $db->prepare($check);
        $check_stmt->bindParam(':slug', $slug);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            $slug .= '-' . time();
        }
        
        $query = "INSERT INTO blog_posts (title, slug, content, excerpt, category_id, author_id, 
                                         featured_image, status, published_at) 
                 VALUES (:title, :slug, :content, :excerpt, :category_id, :author_id, 
                        :featured_image, :status, :published_at)";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':title', $data['title']);
        $stmt->bindParam(':slug', $slug);
        $stmt->bindParam(':content', $data['content']);
        $stmt->bindParam(':excerpt', $data['excerpt']);
        $stmt->bindParam(':category_id', $data['category_id']);
        $stmt->bindParam(':author_id', $user['user_id']);
        $stmt->bindParam(':featured_image', $data['featured_image']);
        $status = $data['status'] ?? 'draft';
        $stmt->bindParam(':status', $status);
        
        $published_at = ($status === 'published') ? date('Y-m-d H:i:s') : null;
        $stmt->bindParam(':published_at', $published_at);
        
        if ($stmt->execute()) {
            Response::success(['post_id' => $db->lastInsertId(), 'slug' => $slug], 'Post created successfully');
        } else {
            Response::error('Failed to create post');
        }
    } catch (Exception $e) {
        Response::error('Failed to create post: ' . $e->getMessage());
    }
} elseif ($method === 'PUT') {
    // Update post - Admin only
    $auth = new Auth();
    $auth->requireAuth();
    $user = $auth->getCurrentUser();
    
    if ($user['role'] !== 'admin') {
        Response::error('Unauthorized. Admin access required.', 403);
    }
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['post_id'])) {
            Response::error('Post ID is required');
        }
        
        $updates = [];
        $params = [':post_id' => $data['post_id']];
        
        if (isset($data['title'])) {
            $updates[] = "title = :title";
            $params[':title'] = $data['title'];
        }
        if (isset($data['content'])) {
            $updates[] = "content = :content";
            $params[':content'] = $data['content'];
        }
        if (isset($data['excerpt'])) {
            $updates[] = "excerpt = :excerpt";
            $params[':excerpt'] = $data['excerpt'];
        }
        if (isset($data['category_id'])) {
            $updates[] = "category_id = :category_id";
            $params[':category_id'] = $data['category_id'];
        }
        if (isset($data['featured_image'])) {
            $updates[] = "featured_image = :featured_image";
            $params[':featured_image'] = $data['featured_image'];
        }
        if (isset($data['status'])) {
            $updates[] = "status = :status";
            $params[':status'] = $data['status'];
            
            if ($data['status'] === 'published') {
                $updates[] = "published_at = NOW()";
            }
        }
        if (isset($data['is_pinned'])) {
            $updates[] = "is_pinned = :is_pinned";
            $params[':is_pinned'] = $data['is_pinned'] ? 1 : 0;
        }
        
        if (empty($updates)) {
            Response::error('No fields to update');
        }
        
        $query = "UPDATE blog_posts SET " . implode(', ', $updates) . " WHERE post_id = :post_id";
        $stmt = $db->prepare($query);
        
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        
        if ($stmt->execute() && $stmt->rowCount() > 0) {
            Response::success(['post_id' => $data['post_id']], 'Post updated successfully');
        } else {
            Response::error('Failed to update post or post not found');
        }
    } catch (Exception $e) {
        Response::error('Failed to update post: ' . $e->getMessage());
    }
} elseif ($method === 'DELETE') {
    // Delete post - Admin only
    $auth = new Auth();
    $auth->requireAuth();
    $user = $auth->getCurrentUser();
    
    if ($user['role'] !== 'admin') {
        Response::error('Unauthorized. Admin access required.', 403);
    }
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['post_id'])) {
            Response::error('Post ID is required');
        }
        
        $query = "DELETE FROM blog_posts WHERE post_id = :post_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':post_id', $data['post_id']);
        
        if ($stmt->execute() && $stmt->rowCount() > 0) {
            Response::success(['post_id' => $data['post_id']], 'Post deleted successfully');
        } else {
            Response::error('Failed to delete post or post not found');
        }
    } catch (Exception $e) {
        Response::error('Failed to delete post: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
