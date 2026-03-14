<?php
/**
 * Building / Floor Device History API
 * Returns device installation history for a building, optionally filtered by floor,
 * status (active / withdrawn / all), and date range.
 *
 * GET params:
 *   building  (required) – e.g. NAC
 *   floor     (optional) – e.g. 2
 *   status    (optional) – all | active | withdrawn  (default: all)
 *   date_from (optional) – YYYY-MM-DD
 *   date_to   (optional) – YYYY-MM-DD
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$auth->requireAuth();

$database = new Database();
$db = $database->getConnection();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    // ── Required param ──────────────────────────────────────────────────────────
    $building = isset($_GET['building']) && trim($_GET['building']) !== ''
        ? strtoupper(trim($_GET['building'])) : null;

    if (!$building) {
        Response::error('Building is required');
    }

    // ── Optional params ──────────────────────────────────────────────────────────
    $floor     = isset($_GET['floor'])     && trim($_GET['floor'])     !== '' ? trim($_GET['floor'])                : null;
    $status    = isset($_GET['status'])    && trim($_GET['status'])    !== '' ? strtolower(trim($_GET['status']))   : 'all';
    $date_from = isset($_GET['date_from']) && trim($_GET['date_from']) !== '' ? trim($_GET['date_from'])            : null;
    $date_to   = isset($_GET['date_to'])   && trim($_GET['date_to'])   !== '' ? trim($_GET['date_to'])              : null;

    if (!in_array($status, ['all', 'active', 'withdrawn'])) {
        Response::error('Invalid status. Use all, active, or withdrawn');
    }
    if ($date_from && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date_from)) {
        Response::error('Invalid date_from format. Use YYYY-MM-DD');
    }
    if ($date_to && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date_to)) {
        Response::error('Invalid date_to format. Use YYYY-MM-DD');
    }

    // ── WHERE clause build ───────────────────────────────────────────────────────
    $where  = "WHERE di.is_deleted = FALSE";
    $params = [];

    // Building: match rooms.building column OR parse building prefix from room_number
    // (mirrors the extractBuildingFromRoomName() fallback in rooms.html / building-device-history.html)
    $where .= " AND (
                    UPPER(r.building) = :building
                    OR (COALESCE(r.building, '') = '' AND UPPER(r.room_number) REGEXP :building_regexp)
                )";
    $params[':building']        = $building;
    $params[':building_regexp'] = '^' . $building;   // e.g.  ^NAC

    // Floor: match rooms.floor column OR parse from room_number (first digit of 3-digit block)
    if ($floor !== null) {
        $where .= " AND (
                        r.floor = :floor
                        OR (COALESCE(r.floor, '') = '' AND r.room_number REGEXP :floor_regexp)
                    )";
        $params[':floor']        = $floor;
        // e.g. floor 2 → room_number like "NAC 2xx"  →  regex  [[:space:]]+2[0-9]{2}
        $params[':floor_regexp'] = '[[:space:]]' . $floor . '[0-9]{2}';
    }

    // Status
    if ($status !== 'all') {
        $where .= " AND di.status = :status";
        $params[':status'] = $status;
    }

    // Date overlap:  record lifecycle [installed_date, IFNULL(withdrawn_date, CURDATE())]
    //                must intersect filter range [date_from, date_to]
    if ($date_from) {
        $where .= " AND IFNULL(di.withdrawn_date, CURDATE()) >= :date_from";
        $params[':date_from'] = $date_from;
    }
    if ($date_to) {
        $where .= " AND di.installed_date <= :date_to";
        $params[':date_to'] = $date_to;
    }

    // ── Main query ───────────────────────────────────────────────────────────────
    $query = "SELECT
                    di.installation_id,
                    r.room_id,
                    r.room_number,
                    r.room_name,
                    COALESCE(r.building, '') AS building,
                    COALESCE(r.floor,    '') AS floor,
                    d.device_id,
                    d.device_unique_id,
                    d.model,
                    d.serial_number,
                    dt.type_name,
                    db.brand_name,
                    di.installed_date,
                    di.withdrawn_date,
                    DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) AS days_in_room,
                    di.status,
                    di.installation_notes,
                    di.withdrawal_notes,
                    COALESCE(di.installer_name,  u_i.full_name) AS installed_by,
                    COALESCE(di.withdrawer_name, u_w.full_name) AS withdrawn_by
                FROM device_installations di
                JOIN  rooms         r   ON di.room_id  = r.room_id
                JOIN  devices       d   ON di.device_id = d.device_id
                LEFT JOIN device_types  dt  ON d.type_id  = dt.type_id
                LEFT JOIN device_brands db  ON d.brand_id = db.brand_id
                LEFT JOIN users         u_i ON di.installed_by  = u_i.user_id
                LEFT JOIN users         u_w ON di.withdrawn_by  = u_w.user_id
                {$where}
                ORDER BY r.room_number, di.installed_date DESC";

    $stmt = $db->prepare($query);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->execute();
    $records = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // ── Statistics ───────────────────────────────────────────────────────────────
    $active_count    = 0;
    $withdrawn_count = 0;
    $room_ids        = [];

    foreach ($records as $rec) {
        if ($rec['status'] === 'active')    $active_count++;
        if ($rec['status'] === 'withdrawn') $withdrawn_count++;
        $room_ids[$rec['room_id']] = true;
    }

    $response = [
        'filters' => [
            'building'  => $building,
            'floor'     => $floor,
            'status'    => $status,
            'date_from' => $date_from,
            'date_to'   => $date_to,
        ],
        'statistics' => [
            'total_records'   => count($records),
            'active_count'    => $active_count,
            'withdrawn_count' => $withdrawn_count,
            'room_count'      => count($room_ids),
        ],
        'records' => $records,
    ];

    Response::success($response, 'Building device history retrieved successfully');

} catch (Exception $e) {
    error_log('Building Device History API Error: ' . $e->getMessage());
    Response::error('Failed to retrieve building device history: ' . $e->getMessage());
}
