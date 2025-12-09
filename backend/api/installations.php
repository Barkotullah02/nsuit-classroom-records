<?php
/**
 * Installations API
 * Manage device installations and withdrawals
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
        // Get installations with filters
        try {
            $where = "WHERE di.is_deleted = FALSE";
            $params = [];
            
            if (isset($_GET['device_id'])) {
                $where .= " AND di.device_id = :device_id";
                $params[':device_id'] = $_GET['device_id'];
            }
            
            if (isset($_GET['room_id'])) {
                $where .= " AND di.room_id = :room_id";
                $params[':room_id'] = $_GET['room_id'];
            }
            
            if (isset($_GET['status'])) {
                $where .= " AND di.status = :status";
                $params[':status'] = $_GET['status'];
            }

            if (isset($_GET['installation_type'])) {
                $where .= " AND di.installation_type = :installation_type";
                $params[':installation_type'] = $_GET['installation_type'];
            }

            $query = "SELECT 
                        di.installation_id,
                        di.device_id,
                        d.device_unique_id,
                        dt.type_name,
                        db.brand_name,
                        d.model,
                        d.serial_number,
                        d.device_status,
                        d.current_issue,
                        d.storage_location as device_storage_location,
                        di.room_id,
                        r.room_number,
                        r.room_name,
                        r.building,
                        di.installed_date,
                        di.withdrawn_date,
                        DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room,
                        di.status,
                        di.installation_type,
                        di.installation_notes,
                        di.withdrawal_notes,
                        di.team_members,
                        di.issue_at_withdrawal,
                        di.storage_location as withdrawal_storage_location,
                        di.gate_pass_number,
                        di.gate_pass_date,
                        COALESCE(di.installer_name, u_installed.full_name) as installed_by_name,
                        di.installer_id as installed_by_id,
                        COALESCE(di.withdrawer_name, u_withdrawn.full_name) as withdrawn_by_name,
                        di.withdrawer_id as withdrawn_by_id,
                        u_data_entry.full_name as data_entry_by_name,
                        di.created_at
                    FROM device_installations di
                    JOIN devices d ON di.device_id = d.device_id
                    JOIN device_types dt ON d.type_id = dt.type_id
                    JOIN device_brands db ON d.brand_id = db.brand_id
                    JOIN rooms r ON di.room_id = r.room_id
                    LEFT JOIN users u_installed ON di.installed_by = u_installed.user_id
                    LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id
                    LEFT JOIN users u_data_entry ON di.data_entry_by = u_data_entry.user_id
                    {$where}
                    ORDER BY di.installed_date DESC";

            $stmt = $db->prepare($query);
            
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            
            $stmt->execute();
            $installations = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($installations, 'Installations retrieved successfully');
        } catch (Exception $e) {
            Response::error('Failed to retrieve installations: ' . $e->getMessage());
        }
        break;

    case 'POST':
        // Create new installation
        try {
            // Validate required fields
            $required = ['device_id', 'room_id', 'installed_date'];
            $errors = [];
            
            foreach ($required as $field) {
                if (!isset($data[$field]) || empty($data[$field])) {
                    $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
                }
            }
            
            if (!empty($errors)) {
                Response::validationError($errors);
            }

            // Check if device already has an active installation
            $check_query = "SELECT installation_id FROM device_installations 
                           WHERE device_id = :device_id AND status = 'active' AND is_deleted = FALSE";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':device_id', $data['device_id']);
            $check_stmt->execute();
            
            if ($check_stmt->rowCount() > 0) {
                Response::error('Device already has an active installation. Please withdraw it first.', 409);
            }

            $user = $auth->getCurrentUser();

            $query = "INSERT INTO device_installations 
                     (device_id, room_id, installed_date, installed_by, installer_name, installer_id, 
                      installation_notes, team_members, installation_type, gate_pass_number, gate_pass_date, data_entry_by, status) 
                     VALUES 
                     (:device_id, :room_id, :installed_date, :installed_by, :installer_name, :installer_id,
                      :installation_notes, :team_members, :installation_type, :gate_pass_number, :gate_pass_date, :data_entry_by, 'active')";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':device_id', $data['device_id']);
            $stmt->bindParam(':room_id', $data['room_id']);
            $stmt->bindParam(':installed_date', $data['installed_date']);
            $stmt->bindParam(':installed_by', $user['user_id']);
            $stmt->bindParam(':installer_name', $data['installer_name']);
            $stmt->bindParam(':installer_id', $data['installer_id']);
            $stmt->bindParam(':installation_notes', $data['installation_notes']);
            $stmt->bindParam(':team_members', $data['team_members']);
            $stmt->bindParam(':installation_type', $data['installation_type']);
            $stmt->bindParam(':gate_pass_number', $data['gate_pass_number']);
            $stmt->bindParam(':gate_pass_date', $data['gate_pass_date']);
            $stmt->bindParam(':data_entry_by', $user['user_id']);

            if ($stmt->execute()) {
                $installation_id = $db->lastInsertId();
                
                // Log action
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id, new_values) 
                             VALUES (:user_id, 'CREATE', 'device_installations', :record_id, :new_values)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $installation_id,
                    ':new_values' => json_encode($data)
                ]);

                Response::success(['installation_id' => $installation_id], 'Device installed successfully', 201);
            }
        } catch (Exception $e) {
            Response::error('Failed to install device: ' . $e->getMessage());
        }
        break;

    case 'PUT':
        // Withdraw device (update installation)
        try {
            if (!isset($data['installation_id'])) {
                Response::error('Installation ID is required');
            }

            if (!isset($data['withdrawn_date'])) {
                Response::error('Withdrawn date is required');
            }

            $user = $auth->getCurrentUser();

            // Get old values for audit
            $old_query = "SELECT * FROM device_installations WHERE installation_id = :installation_id";
            $old_stmt = $db->prepare($old_query);
            $old_stmt->bindParam(':installation_id', $data['installation_id']);
            $old_stmt->execute();
            $old_values = $old_stmt->fetch(PDO::FETCH_ASSOC);

            $query = "UPDATE device_installations SET 
                     withdrawn_date = :withdrawn_date,
                     withdrawn_by = :withdrawn_by,
                     withdrawer_name = :withdrawer_name,
                     withdrawer_id = :withdrawer_id,
                     withdrawal_notes = :withdrawal_notes,
                     issue_at_withdrawal = :issue_at_withdrawal,
                     storage_location = :storage_location,
                     data_entry_by = :data_entry_by,
                     status = 'withdrawn'
                     WHERE installation_id = :installation_id";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':installation_id', $data['installation_id']);
            $stmt->bindParam(':withdrawn_date', $data['withdrawn_date']);
            $stmt->bindParam(':withdrawn_by', $user['user_id']);
            $stmt->bindParam(':withdrawer_name', $data['withdrawer_name']);
            $stmt->bindParam(':withdrawer_id', $data['withdrawer_id']);
            $stmt->bindParam(':withdrawal_notes', $data['withdrawal_notes']);
            $stmt->bindParam(':issue_at_withdrawal', $data['issue_at_withdrawal']);
            $stmt->bindParam(':storage_location', $data['storage_location']);
            $stmt->bindParam(':data_entry_by', $user['user_id']);

            if ($stmt->execute()) {
                // Log action
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values) 
                             VALUES (:user_id, 'UPDATE', 'device_installations', :record_id, :old_values, :new_values)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $data['installation_id'],
                    ':old_values' => json_encode($old_values),
                    ':new_values' => json_encode($data)
                ]);

                Response::success([], 'Device withdrawn successfully');
            }
        } catch (Exception $e) {
            Response::error('Failed to withdraw device: ' . $e->getMessage());
        }
        break;

    case 'DELETE':
        // Soft delete installation
        $auth->requireAdmin();
        
        try {
            $installation_id = $_GET['installation_id'] ?? null;
            
            if (!$installation_id) {
                Response::error('Installation ID is required');
            }

            $user = $auth->getCurrentUser();
            
            $query = "UPDATE device_installations 
                     SET is_deleted = TRUE, deleted_at = NOW(), deleted_by = :deleted_by 
                     WHERE installation_id = :installation_id";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':installation_id', $installation_id);
            $stmt->bindParam(':deleted_by', $user['user_id']);

            if ($stmt->execute()) {
                // Log action
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id) 
                             VALUES (:user_id, 'SOFT_DELETE', 'device_installations', :record_id)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $installation_id
                ]);

                Response::success([], 'Installation record deleted successfully');
            }
        } catch (Exception $e) {
            Response::error('Failed to delete installation: ' . $e->getMessage());
        }
        break;

    default:
        Response::error('Method not allowed', 405);
        break;
}
