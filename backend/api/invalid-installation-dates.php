<?php
/**
 * Invalid Installation Dates API
 * - GET: list invalid installation date records
 * - PUT: update date fields for an installation (super_admin only)
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

function isValidSqlDate($value) {
    if ($value === null || $value === '') {
        return true;
    }

    if ($value === '0000-00-00') {
        return false;
    }

    $date = DateTime::createFromFormat('Y-m-d', $value);
    return $date && $date->format('Y-m-d') === $value;
}

function normalizeDateValue($value) {
    if ($value === null || $value === '' || $value === '0000-00-00') {
        return null;
    }
    return $value;
}

switch ($method) {
    case 'GET':
        try {
            $query = "SELECT 
                        di.installation_id,
                        di.device_id,
                        d.device_unique_id,
                        dt.type_name,
                        db.brand_name,
                        d.model,
                        di.room_id,
                        r.room_number,
                        r.room_name,
                        r.building,
                        di.installed_date,
                        di.withdrawn_date,
                        di.gate_pass_date,
                        di.status,
                        di.installation_type,
                        di.gate_pass_number,
                        di.created_at,
                        di.updated_at,
                        CASE
                               WHEN di.installed_date IS NULL OR CAST(di.installed_date AS CHAR) = '0000-00-00' THEN 'MISSING_OR_ZERO_INSTALLED_DATE'
                               WHEN di.status = 'withdrawn' AND (di.withdrawn_date IS NULL OR CAST(di.withdrawn_date AS CHAR) = '0000-00-00') THEN 'WITHDRAWN_WITHOUT_WITHDRAWN_DATE'
                               WHEN di.withdrawn_date IS NOT NULL AND CAST(di.withdrawn_date AS CHAR) != '0000-00-00' 
                                   AND di.installed_date IS NOT NULL AND CAST(di.installed_date AS CHAR) != '0000-00-00'
                                 AND di.withdrawn_date < di.installed_date THEN 'WITHDRAWN_BEFORE_INSTALLED'
                            ELSE 'UNKNOWN'
                        END AS invalid_reason
                    FROM device_installations di
                    JOIN devices d ON di.device_id = d.device_id
                    JOIN device_types dt ON d.type_id = dt.type_id
                    JOIN device_brands db ON d.brand_id = db.brand_id
                    JOIN rooms r ON di.room_id = r.room_id
                    WHERE di.is_deleted = FALSE
                      AND (
                          di.installed_date IS NULL
                          OR CAST(di.installed_date AS CHAR) = '0000-00-00'
                          OR (
                              di.status = 'withdrawn'
                              AND (di.withdrawn_date IS NULL OR CAST(di.withdrawn_date AS CHAR) = '0000-00-00')
                          )
                          OR (
                              di.withdrawn_date IS NOT NULL
                              AND CAST(di.withdrawn_date AS CHAR) != '0000-00-00'
                              AND di.installed_date IS NOT NULL
                              AND CAST(di.installed_date AS CHAR) != '0000-00-00'
                              AND di.withdrawn_date < di.installed_date
                          )
                      )
                    ORDER BY di.updated_at DESC, di.created_at DESC";

            $stmt = $db->prepare($query);
            $stmt->execute();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($rows, 'Invalid installation dates retrieved successfully');
        } catch (Exception $e) {
            Response::error('Failed to retrieve invalid installation dates: ' . $e->getMessage());
        }
        break;

    case 'PUT':
        $auth->requireAdmin();

        try {
            if (!isset($data['installation_id']) || empty($data['installation_id'])) {
                Response::error('Installation ID is required');
            }

            if (!array_key_exists('installed_date', $data) && !array_key_exists('withdrawn_date', $data) && !array_key_exists('gate_pass_date', $data)) {
                Response::error('At least one date field is required (installed_date, withdrawn_date, gate_pass_date)');
            }

            $installedDate = normalizeDateValue($data['installed_date'] ?? null);
            $withdrawnDate = normalizeDateValue($data['withdrawn_date'] ?? null);
            $gatePassDate = normalizeDateValue($data['gate_pass_date'] ?? null);

            $errors = [];

            if (!isValidSqlDate($installedDate)) {
                $errors['installed_date'] = 'Installed date must be a valid date in YYYY-MM-DD format';
            }
            if (!isValidSqlDate($withdrawnDate)) {
                $errors['withdrawn_date'] = 'Withdrawn date must be a valid date in YYYY-MM-DD format';
            }
            if (!isValidSqlDate($gatePassDate)) {
                $errors['gate_pass_date'] = 'Gate pass date must be a valid date in YYYY-MM-DD format';
            }

            if (!empty($installedDate) && !empty($withdrawnDate) && $withdrawnDate < $installedDate) {
                $errors['date_order'] = 'Withdrawn date cannot be earlier than installed date';
            }

            if (!empty($errors)) {
                Response::validationError($errors);
            }

            $existingQuery = "SELECT * FROM device_installations WHERE installation_id = :installation_id AND is_deleted = FALSE";
            $existingStmt = $db->prepare($existingQuery);
            $existingStmt->bindParam(':installation_id', $data['installation_id']);
            $existingStmt->execute();
            $existing = $existingStmt->fetch(PDO::FETCH_ASSOC);

            if (!$existing) {
                Response::notFound('Installation record not found');
            }

            $finalInstalledDate = array_key_exists('installed_date', $data) ? $installedDate : $existing['installed_date'];
            $finalWithdrawnDate = array_key_exists('withdrawn_date', $data) ? $withdrawnDate : $existing['withdrawn_date'];
            $finalGatePassDate = array_key_exists('gate_pass_date', $data) ? $gatePassDate : $existing['gate_pass_date'];

            if (!empty($finalInstalledDate) && !empty($finalWithdrawnDate) && $finalWithdrawnDate < $finalInstalledDate) {
                Response::validationError([
                    'date_order' => 'Withdrawn date cannot be earlier than installed date after update'
                ]);
            }

            $setParts = [];
            $params = [':installation_id' => $data['installation_id']];

            if (array_key_exists('installed_date', $data)) {
                $setParts[] = 'installed_date = :installed_date';
                $params[':installed_date'] = $installedDate;
            }

            if (array_key_exists('withdrawn_date', $data)) {
                $setParts[] = 'withdrawn_date = :withdrawn_date';
                $params[':withdrawn_date'] = $withdrawnDate;
            }

            if (array_key_exists('gate_pass_date', $data)) {
                $setParts[] = 'gate_pass_date = :gate_pass_date';
                $params[':gate_pass_date'] = $gatePassDate;
            }

            if (empty($setParts)) {
                Response::error('No valid date fields provided for update');
            }

            $setParts[] = 'data_entry_by = :data_entry_by';
            $user = $auth->getCurrentUser();
            $params[':data_entry_by'] = $user['user_id'];

            $query = "UPDATE device_installations SET " . implode(', ', $setParts) . " WHERE installation_id = :installation_id";
            $stmt = $db->prepare($query);

            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }

            $stmt->execute();

            $newQuery = "SELECT installation_id, installed_date, withdrawn_date, gate_pass_date FROM device_installations WHERE installation_id = :installation_id";
            $newStmt = $db->prepare($newQuery);
            $newStmt->bindParam(':installation_id', $data['installation_id']);
            $newStmt->execute();
            $newValues = $newStmt->fetch(PDO::FETCH_ASSOC);

            $logQuery = "INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values) 
                         VALUES (:user_id, 'UPDATE_INVALID_DATES', 'device_installations', :record_id, :old_values, :new_values)";
            $logStmt = $db->prepare($logQuery);
            $logStmt->execute([
                ':user_id' => $user['user_id'],
                ':record_id' => $data['installation_id'],
                ':old_values' => json_encode([
                    'installed_date' => $existing['installed_date'],
                    'withdrawn_date' => $existing['withdrawn_date'],
                    'gate_pass_date' => $existing['gate_pass_date']
                ]),
                ':new_values' => json_encode($newValues)
            ]);

            Response::success($newValues, 'Installation dates updated successfully');
        } catch (Exception $e) {
            Response::error('Failed to update installation dates: ' . $e->getMessage());
        }
        break;

    default:
        Response::error('Method not allowed', 405);
        break;
}
