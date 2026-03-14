<?php
/**
 * Database Configuration
 */

class Database {
    private $db_name = "classroom_devices";
    private $username = "classroommysqlserver";
    private $password = "classroomubuntumysql";
    private $charset = "utf8mb4";
    private $socket = "/var/run/mysqld/mysqld.sock";

    public $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $dsn = "mysql:unix_socket={$this->socket};dbname={$this->db_name};charset={$this->charset}";
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];
            $this->conn = new PDO($dsn, $this->username, $this->password, $options);
        } catch (PDOException $e) {
            error_log("Database connection error: " . $e->getMessage());
            return null;
        }

        return $this->conn;
    }
}
