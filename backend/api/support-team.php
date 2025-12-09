<?php
/**
 * Support Team Members API
 * Manage support team members (Admin only)
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$auth->requireAuth();

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];
$data = json_decode(file_get_contents("php://input"), true);

switch ($method) {
    case 'GET':
        // Get all support team members
        try {
            $where = "WHERE 1=1";
            $params = [];
            
            if (isset($_GET['is_active'])) {
                $where .= " AND is_active = :is_active";
                $params[':is_active'] = $_GET['is_active'];
            }

            $query = "SELECT 
                        stm.member_id,
                        stm.user_id,
                        stm.member_name,
                        stm.member_email,
                        stm.member_phone,
                        stm.department,
                        stm.is_active,
                        stm.created_at,
                        u.full_name as created_by_name
                    FROM support_team_members stm
                    LEFT JOIN users u ON stm.created_by = u.user_id
                    {$where}
                    ORDER BY stm.member_name";

            $stmt = $db->prepare($query);
            
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            
            $stmt->execute();
            $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($members, 'Support team members retrieved successfully');
        } catch (Exception $e) {
            Response::error('Failed to retrieve support team members: ' . $e->getMessage());
        }
        break;

    case 'POST':
        // Create new support team member (Admin only)
        $auth->requireAdmin();
        
        try {
            $required = ['member_name'];
            $errors = [];
            
            foreach ($required as $field) {
                if (!isset($data[$field]) || empty($data[$field])) {
                    $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
                }
            }
            
            if (!empty($errors)) {
                Response::validationError($errors);
            }

            $user = $auth->getCurrentUser();

            $query = "INSERT INTO support_team_members 
                     (member_name, member_email, member_phone, department, user_id, created_by) 
                     VALUES 
                     (:member_name, :member_email, :member_phone, :department, :user_id, :created_by)";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':member_name', $data['member_name']);
            $stmt->bindParam(':member_email', $data['member_email']);
            $stmt->bindParam(':member_phone', $data['member_phone']);
            $stmt->bindParam(':department', $data['department']);
            $stmt->bindParam(':user_id', $data['user_id']);
            $stmt->bindParam(':created_by', $user['user_id']);

            if ($stmt->execute()) {
                $member_id = $db->lastInsertId();
                Response::success(['member_id' => $member_id], 'Support team member added successfully', 201);
            }
        } catch (Exception $e) {
            Response::error('Failed to add support team member: ' . $e->getMessage());
        }
        break;

    case 'PUT':
        // Update support team member (Admin only)
        $auth->requireAdmin();
        
        try {
            if (!isset($data['member_id'])) {
                Response::error('Member ID is required');
            }

            $query = "UPDATE support_team_members SET 
                     member_name = :member_name,
                     member_email = :member_email,
                     member_phone = :member_phone,
                     department = :department,
                     user_id = :user_id,
                     is_active = :is_active
                     WHERE member_id = :member_id";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':member_id', $data['member_id']);
            $stmt->bindParam(':member_name', $data['member_name']);
            $stmt->bindParam(':member_email', $data['member_email']);
            $stmt->bindParam(':member_phone', $data['member_phone']);
            $stmt->bindParam(':department', $data['department']);
            $stmt->bindParam(':user_id', $data['user_id']);
            $stmt->bindParam(':is_active', $data['is_active']);

            if ($stmt->execute()) {
                Response::success([], 'Support team member updated successfully');
            }
        } catch (Exception $e) {
            Response::error('Failed to update support team member: ' . $e->getMessage());
        }
        break;

    case 'DELETE':
        // Delete support team member (Admin only)
        $auth->requireAdmin();
        
        try {
            $member_id = $_GET['member_id'] ?? null;
            
            if (!$member_id) {
                Response::error('Member ID is required');
            }

            // Check if member has support records
            $check_query = "SELECT COUNT(*) as count FROM classroom_support_records 
                           WHERE member_id = :member_id AND is_deleted = FALSE";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':member_id', $member_id);
            $check_stmt->execute();
            $result = $check_stmt->fetch(PDO::FETCH_ASSOC);

            if ($result['count'] > 0) {
                Response::error('Cannot delete member with existing support records. Set to inactive instead.', 409);
            }

            $query = "DELETE FROM support_team_members WHERE member_id = :member_id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':member_id', $member_id);

            if ($stmt->execute()) {
                Response::success([], 'Support team member deleted successfully');
            }
        } catch (Exception $e) {
            Response::error('Failed to delete support team member: ' . $e->getMessage());
        }
        break;

    default:
        Response::error('Method not allowed', 405);
        break;
}
