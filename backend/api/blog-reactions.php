<?php
/**
 * Blog Reactions API
 * Manage blog post reactions
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$auth->requireAuth();

$database = new Database();
$db = $database->getConnection();
$user = $auth->getCurrentUser();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Get reactions for a post
    try {
        $post_id = $_GET['post_id'] ?? null;
        
        if (!$post_id) {
            Response::error('Post ID is required');
        }
        
        $query = "SELECT reaction_type, COUNT(*) as count
                 FROM blog_reactions
                 WHERE post_id = :post_id
                 GROUP BY reaction_type";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':post_id', $post_id);
        $stmt->execute();
        
        $reactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Check user's reaction
        $user_query = "SELECT reaction_type FROM blog_reactions 
                      WHERE post_id = :post_id AND user_id = :user_id";
        $user_stmt = $db->prepare($user_query);
        $user_stmt->bindParam(':post_id', $post_id);
        $user_stmt->bindParam(':user_id', $user['user_id']);
        $user_stmt->execute();
        $user_reaction = $user_stmt->fetch(PDO::FETCH_ASSOC);
        
        Response::success([
            'reactions' => $reactions,
            'user_reaction' => $user_reaction ? $user_reaction['reaction_type'] : null
        ], 'Reactions retrieved successfully');
    } catch (Exception $e) {
        Response::error('Failed to retrieve reactions: ' . $e->getMessage());
    }
} elseif ($method === 'POST') {
    // Add or update reaction
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['post_id']) || empty($data['reaction_type'])) {
            Response::error('Post ID and reaction type are required');
        }
        
        $valid_types = ['like', 'love', 'celebrate', 'insightful'];
        if (!in_array($data['reaction_type'], $valid_types)) {
            Response::error('Invalid reaction type');
        }
        
        // Check if user already reacted
        $check = "SELECT reaction_id FROM blog_reactions 
                 WHERE post_id = :post_id AND user_id = :user_id";
        $check_stmt = $db->prepare($check);
        $check_stmt->bindParam(':post_id', $data['post_id']);
        $check_stmt->bindParam(':user_id', $user['user_id']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            // Update existing reaction
            $query = "UPDATE blog_reactions SET reaction_type = :reaction_type 
                     WHERE post_id = :post_id AND user_id = :user_id";
        } else {
            // Insert new reaction
            $query = "INSERT INTO blog_reactions (post_id, user_id, reaction_type) 
                     VALUES (:post_id, :user_id, :reaction_type)";
        }
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':post_id', $data['post_id']);
        $stmt->bindParam(':user_id', $user['user_id']);
        $stmt->bindParam(':reaction_type', $data['reaction_type']);
        
        if ($stmt->execute()) {
            Response::success(['reaction_type' => $data['reaction_type']], 'Reaction saved successfully');
        } else {
            Response::error('Failed to save reaction');
        }
    } catch (Exception $e) {
        Response::error('Failed to save reaction: ' . $e->getMessage());
    }
} elseif ($method === 'DELETE') {
    // Remove reaction
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['post_id'])) {
            Response::error('Post ID is required');
        }
        
        $query = "DELETE FROM blog_reactions WHERE post_id = :post_id AND user_id = :user_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':post_id', $data['post_id']);
        $stmt->bindParam(':user_id', $user['user_id']);
        
        if ($stmt->execute()) {
            Response::success(null, 'Reaction removed successfully');
        } else {
            Response::error('Failed to remove reaction');
        }
    } catch (Exception $e) {
        Response::error('Failed to remove reaction: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
