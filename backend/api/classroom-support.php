<?php
/**
 * Classroom Support Records API
 * Manage classroom support activities
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
        // Get support records with filters
        try {
            $where = "WHERE csr.is_deleted = FALSE";
            $params = [];
            
            if (isset($_GET['member_id'])) {
                $where .= " AND csr.member_id = :member_id";
                $params[':member_id'] = $_GET['member_id'];
            }
            
            if (isset($_GET['location'])) {
                $where .= " AND csr.location LIKE :location";
                $params[':location'] = '%' . $_GET['location'] . '%';
            }
            
            if (isset($_GET['date_from'])) {
                $where .= " AND csr.support_date >= :date_from";
                $params[':date_from'] = $_GET['date_from'];
            }
            
            if (isset($_GET['date_to'])) {
                $where .= " AND csr.support_date <= :date_to";
                $params[':date_to'] = $_GET['date_to'];
            }
            
            if (isset($_GET['status'])) {
                $where .= " AND csr.status = :status";
                $params[':status'] = $_GET['status'];
            }
            
            if (isset($_GET['issue_type'])) {
                $where .= " AND csr.issue_type = :issue_type";
                $params[':issue_type'] = $_GET['issue_type'];
            }

            $query = "SELECT 
                        csr.support_id,
                        csr.member_id,
                        stm.member_name,
                        stm.department,
                        csr.support_date,
                        csr.support_time,
                        CONCAT(csr.support_date, ' ', csr.support_time) as support_datetime,
                        csr.location,
                        csr.room_id,
                        r.room_name,
                        r.building,
                        csr.support_description,
                        csr.issue_type,
                        csr.priority,
                        csr.status,
                        csr.devices_involved,
                        csr.duration_minutes,
                        csr.faculty_name,
                        csr.notes,
                        csr.created_by,
                        u.full_name as created_by_name,
                        csr.created_at,
                        csr.updated_at
                    FROM classroom_support_records csr
                    JOIN support_team_members stm ON csr.member_id = stm.member_id
                    LEFT JOIN rooms r ON csr.room_id = r.room_id
                    LEFT JOIN users u ON csr.created_by = u.user_id
                    {$where}
                    ORDER BY csr.support_date DESC, csr.support_time DESC";

            $stmt = $db->prepare($query);
            
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            
            $stmt->execute();
            $records = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($records, 'Support records retrieved successfully');
        } catch (Exception $e) {
            Response::error('Failed to retrieve support records: ' . $e->getMessage());
        }
        break;

    case 'POST':
        // Create new support record
        try {
            $required = ['member_id', 'support_date', 'support_time', 'location', 'support_description'];
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

            $query = "INSERT INTO classroom_support_records 
                     (member_id, support_date, support_time, location, room_id, support_description, 
                      issue_type, priority, status, devices_involved, duration_minutes, faculty_name, 
                      notes, created_by) 
                     VALUES 
                     (:member_id, :support_date, :support_time, :location, :room_id, :support_description,
                      :issue_type, :priority, :status, :devices_involved, :duration_minutes, :faculty_name,
                      :notes, :created_by)";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':member_id', $data['member_id']);
            $stmt->bindParam(':support_date', $data['support_date']);
            $stmt->bindParam(':support_time', $data['support_time']);
            $stmt->bindParam(':location', $data['location']);
            $stmt->bindParam(':room_id', $data['room_id']);
            $stmt->bindParam(':support_description', $data['support_description']);
            $stmt->bindParam(':issue_type', $data['issue_type']);
            $stmt->bindParam(':priority', $data['priority']);
            $stmt->bindParam(':status', $data['status']);
            $stmt->bindParam(':devices_involved', $data['devices_involved']);
            $stmt->bindParam(':duration_minutes', $data['duration_minutes']);
            $stmt->bindParam(':faculty_name', $data['faculty_name']);
            $stmt->bindParam(':notes', $data['notes']);
            $stmt->bindParam(':created_by', $user['user_id']);

            if ($stmt->execute()) {
                $support_id = $db->lastInsertId();
                Response::success(['support_id' => $support_id], 'Support record created successfully', 201);
            }
        } catch (Exception $e) {
            Response::error('Failed to create support record: ' . $e->getMessage());
        }
        break;

    case 'PUT':
        // Update support record
        try {
            if (!isset($data['support_id'])) {
                Response::error('Support ID is required');
            }

            $user = $auth->getCurrentUser();
            $isAdmin = $user['role'] === 'admin';

            // Check if user owns this record or is admin
            $check_query = "SELECT created_by FROM classroom_support_records WHERE support_id = :support_id";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':support_id', $data['support_id']);
            $check_stmt->execute();
            $record = $check_stmt->fetch(PDO::FETCH_ASSOC);

            if (!$record) {
                Response::error('Support record not found', 404);
            }

            if (!$isAdmin && $record['created_by'] != $user['user_id']) {
                Response::error('Unauthorized. You can only edit your own records.', 403);
            }

            $query = "UPDATE classroom_support_records SET 
                     member_id = :member_id,
                     support_date = :support_date,
                     support_time = :support_time,
                     location = :location,
                     room_id = :room_id,
                     support_description = :support_description,
                     issue_type = :issue_type,
                     priority = :priority,
                     status = :status,
                     devices_involved = :devices_involved,
                     duration_minutes = :duration_minutes,
                     faculty_name = :faculty_name,
                     notes = :notes
                     WHERE support_id = :support_id";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':support_id', $data['support_id']);
            $stmt->bindParam(':member_id', $data['member_id']);
            $stmt->bindParam(':support_date', $data['support_date']);
            $stmt->bindParam(':support_time', $data['support_time']);
            $stmt->bindParam(':location', $data['location']);
            $stmt->bindParam(':room_id', $data['room_id']);
            $stmt->bindParam(':support_description', $data['support_description']);
            $stmt->bindParam(':issue_type', $data['issue_type']);
            $stmt->bindParam(':priority', $data['priority']);
            $stmt->bindParam(':status', $data['status']);
            $stmt->bindParam(':devices_involved', $data['devices_involved']);
            $stmt->bindParam(':duration_minutes', $data['duration_minutes']);
            $stmt->bindParam(':faculty_name', $data['faculty_name']);
            $stmt->bindParam(':notes', $data['notes']);

            if ($stmt->execute()) {
                Response::success([], 'Support record updated successfully');
            }
        } catch (Exception $e) {
            Response::error('Failed to update support record: ' . $e->getMessage());
        }
        break;

    case 'DELETE':
        // Soft delete support record
        try {
            $support_id = $_GET['support_id'] ?? null;
            
            if (!$support_id) {
                Response::error('Support ID is required');
            }

            $user = $auth->getCurrentUser();
            $isAdmin = $user['role'] === 'admin';

            // Check ownership
            $check_query = "SELECT created_by FROM classroom_support_records WHERE support_id = :support_id";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':support_id', $support_id);
            $check_stmt->execute();
            $record = $check_stmt->fetch(PDO::FETCH_ASSOC);

            if (!$record) {
                Response::error('Support record not found', 404);
            }

            if (!$isAdmin && $record['created_by'] != $user['user_id']) {
                Response::error('Unauthorized. You can only delete your own records.', 403);
            }

            $query = "UPDATE classroom_support_records 
                     SET is_deleted = TRUE, deleted_at = NOW(), deleted_by = :deleted_by 
                     WHERE support_id = :support_id";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':support_id', $support_id);
            $stmt->bindParam(':deleted_by', $user['user_id']);

            if ($stmt->execute()) {
                Response::success([], 'Support record deleted successfully');
            }
        } catch (Exception $e) {
            Response::error('Failed to delete support record: ' . $e->getMessage());
        }
        break;

    default:
        Response::error('Method not allowed', 405);
        break;
}
