<?php
/**
 * Blog Comments API
 * Manage blog comments and replies
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Public endpoint - get comments for a post
    try {
        $post_id = $_GET['post_id'] ?? null;
        
        if (!$post_id) {
            Response::error('Post ID is required');
        }
        
        $query = "SELECT c.*, u.full_name as user_name, u.username,
                        (SELECT COUNT(*) FROM blog_comments WHERE parent_comment_id = c.comment_id AND is_deleted = FALSE) as reply_count
                 FROM blog_comments c
                 JOIN users u ON c.user_id = u.user_id
                 WHERE c.post_id = :post_id AND c.is_deleted = FALSE
                 ORDER BY c.created_at ASC";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':post_id', $post_id);
        $stmt->execute();
        
        $all_comments = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Organize comments into threads (parent comments with their replies)
        $comments = [];
        $replies = [];
        
        foreach ($all_comments as $comment) {
            if ($comment['parent_comment_id'] === null) {
                $comment['replies'] = [];
                $comments[$comment['comment_id']] = $comment;
            } else {
                if (!isset($replies[$comment['parent_comment_id']])) {
                    $replies[$comment['parent_comment_id']] = [];
                }
                $replies[$comment['parent_comment_id']][] = $comment;
            }
        }
        
        // Add replies to their parent comments
        foreach ($replies as $parent_id => $reply_list) {
            if (isset($comments[$parent_id])) {
                $comments[$parent_id]['replies'] = $reply_list;
            }
        }
        
        Response::success(array_values($comments), 'Comments retrieved successfully');
    } catch (Exception $e) {
        Response::error('Failed to retrieve comments: ' . $e->getMessage());
    }
} elseif ($method === 'POST') {
    // Add comment - Requires auth
    $auth = new Auth();
    $auth->requireAuth();
    $user = $auth->getCurrentUser();
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['post_id']) || empty($data['comment_text'])) {
            Response::error('Post ID and comment text are required');
        }
        
        $query = "INSERT INTO blog_comments (post_id, user_id, parent_comment_id, comment_text) 
                 VALUES (:post_id, :user_id, :parent_comment_id, :comment_text)";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':post_id', $data['post_id']);
        $stmt->bindParam(':user_id', $user['user_id']);
        $parent_comment_id = $data['parent_comment_id'] ?? null;
        $stmt->bindParam(':parent_comment_id', $parent_comment_id);
        $stmt->bindParam(':comment_text', $data['comment_text']);
        
        if ($stmt->execute()) {
            Response::success(['comment_id' => $db->lastInsertId()], 'Comment posted successfully');
        } else {
            Response::error('Failed to post comment');
        }
    } catch (Exception $e) {
        Response::error('Failed to post comment: ' . $e->getMessage());
    }
} elseif ($method === 'PUT') {
    // Update comment - Only comment owner or admin
    $auth = new Auth();
    $auth->requireAuth();
    $user = $auth->getCurrentUser();
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['comment_id']) || empty($data['comment_text'])) {
            Response::error('Comment ID and text are required');
        }
        
        // Check ownership
        $check = "SELECT user_id FROM blog_comments WHERE comment_id = :comment_id";
        $check_stmt = $db->prepare($check);
        $check_stmt->bindParam(':comment_id', $data['comment_id']);
        $check_stmt->execute();
        $comment = $check_stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$comment) {
            Response::error('Comment not found', 404);
        }
        
        if ($comment['user_id'] != $user['user_id'] && $user['role'] !== 'admin') {
            Response::error('Unauthorized', 403);
        }
        
        $query = "UPDATE blog_comments SET comment_text = :comment_text WHERE comment_id = :comment_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':comment_text', $data['comment_text']);
        $stmt->bindParam(':comment_id', $data['comment_id']);
        
        if ($stmt->execute()) {
            Response::success(['comment_id' => $data['comment_id']], 'Comment updated successfully');
        } else {
            Response::error('Failed to update comment');
        }
    } catch (Exception $e) {
        Response::error('Failed to update comment: ' . $e->getMessage());
    }
} elseif ($method === 'DELETE') {
    // Delete comment - Only comment owner or admin
    $auth = new Auth();
    $auth->requireAuth();
    $user = $auth->getCurrentUser();
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['comment_id'])) {
            Response::error('Comment ID is required');
        }
        
        // Check ownership
        $check = "SELECT user_id FROM blog_comments WHERE comment_id = :comment_id";
        $check_stmt = $db->prepare($check);
        $check_stmt->bindParam(':comment_id', $data['comment_id']);
        $check_stmt->execute();
        $comment = $check_stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$comment) {
            Response::error('Comment not found', 404);
        }
        
        if ($comment['user_id'] != $user['user_id'] && $user['role'] !== 'admin') {
            Response::error('Unauthorized', 403);
        }
        
        // Soft delete
        $query = "UPDATE blog_comments SET is_deleted = TRUE WHERE comment_id = :comment_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':comment_id', $data['comment_id']);
        
        if ($stmt->execute()) {
            Response::success(['comment_id' => $data['comment_id']], 'Comment deleted successfully');
        } else {
            Response::error('Failed to delete comment');
        }
    } catch (Exception $e) {
        Response::error('Failed to delete comment: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
