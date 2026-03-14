-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 08, 2026 at 11:10 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `classroom_devices`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_device_history` (IN `p_device_id` INT)   BEGIN
    SELECT 
        di.installation_id,
        r.room_number,
        r.room_name,
        di.installed_date,
        di.withdrawn_date,
        DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room,
        di.status,
        u_installed.full_name as installed_by,
        u_withdrawn.full_name as withdrawn_by,
        di.installation_notes,
        di.withdrawal_notes
    FROM device_installations di
    JOIN rooms r ON di.room_id = r.room_id
    JOIN users u_installed ON di.installed_by = u_installed.user_id
    LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id
    WHERE di.device_id = p_device_id
        AND di.is_deleted = FALSE
    ORDER BY di.installed_date DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_restore_device` (IN `p_device_id` INT, IN `p_restored_by` INT)   BEGIN
    UPDATE devices 
    SET is_deleted = FALSE,
        deleted_at = NULL,
        deleted_by = NULL
    WHERE device_id = p_device_id;
    
    -- Log the action
    INSERT INTO audit_log (user_id, action, table_name, record_id, ip_address)
    VALUES (p_restored_by, 'RESTORE', 'devices', p_device_id, 'SYSTEM');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_soft_delete_device` (IN `p_device_id` INT, IN `p_deleted_by` INT)   BEGIN
    UPDATE devices 
    SET is_deleted = TRUE,
        deleted_at = CURRENT_TIMESTAMP,
        deleted_by = p_deleted_by
    WHERE device_id = p_device_id;
    
    -- Log the action
    INSERT INTO audit_log (user_id, action, table_name, record_id, ip_address)
    VALUES (p_deleted_by, 'SOFT_DELETE', 'devices', p_device_id, 'SYSTEM');
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--

CREATE TABLE `audit_log` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action` varchar(50) NOT NULL COMMENT 'CREATE, UPDATE, DELETE, RESTORE, LOGIN, LOGOUT',
  `table_name` varchar(50) NOT NULL,
  `record_id` int(11) NOT NULL,
  `old_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_values`)),
  `new_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_values`)),
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_log`
--

INSERT INTO `audit_log` (`log_id`, `user_id`, `action`, `table_name`, `record_id`, `old_values`, `new_values`, `ip_address`, `user_agent`, `created_at`) VALUES
(1, 1, 'CREATE', 'devices', 18, NULL, '{\"device_unique_id\":\"50-ITD-00508-00553\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201217\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:07'),
(2, 1, 'CREATE', 'devices', 19, NULL, '{\"device_unique_id\":\"50-ITD-00508-00564\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC25350185\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:08'),
(3, 1, 'CREATE', 'devices', 20, NULL, '{\"device_unique_id\":\"50-ITD-00508-00565\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201221\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:08'),
(4, 1, 'CREATE', 'devices', 21, NULL, '{\"device_unique_id\":\"50-ITD-00508-00555\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501067\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:08'),
(5, 1, 'CREATE', 'devices', 22, NULL, '{\"device_unique_id\":\"50-ITD-00508-00566\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501170\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:08'),
(6, 1, 'CREATE', 'devices', 23, NULL, '{\"device_unique_id\":\"50-ITD-00508-00554\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201199\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:08'),
(7, 1, 'CREATE', 'devices', 24, NULL, '{\"device_unique_id\":\"50-ITD-00508-00567\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201200\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:08'),
(8, 1, 'CREATE', 'devices', 25, NULL, '{\"device_unique_id\":\"50-ITD-00508-00568\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201191\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:08'),
(9, 1, 'CREATE', 'devices', 26, NULL, '{\"device_unique_id\":\"50-ITD-00508-00571\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501148\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:09'),
(10, 1, 'CREATE', 'devices', 27, NULL, '{\"device_unique_id\":\"50-ITD-00508-00569\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201222\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:09'),
(11, 1, 'CREATE', 'devices', 28, NULL, '{\"device_unique_id\":\"50-ITD-00508-00572\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501139\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:09'),
(12, 1, 'CREATE', 'devices', 29, NULL, '{\"device_unique_id\":\"50-ITD-00508-00552\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501178\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:09'),
(13, 1, 'CREATE', 'devices', 30, NULL, '{\"device_unique_id\":\"50-ITD-00508-00551\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501165\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:09'),
(14, 1, 'CREATE', 'devices', 31, NULL, '{\"device_unique_id\":\"50-ITD-00508-00559\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501146\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:10'),
(15, 1, 'CREATE', 'devices', 32, NULL, '{\"device_unique_id\":\"50-ITD-00508-00560\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501167\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:10'),
(16, 1, 'CREATE', 'devices', 33, NULL, '{\"device_unique_id\":\"50-ITD-00508-00561\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201216\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:10'),
(17, 1, 'CREATE', 'devices', 34, NULL, '{\"device_unique_id\":\"50-ITD-00508-00562\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201233\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:10'),
(18, 1, 'CREATE', 'devices', 35, NULL, '{\"device_unique_id\":\"50-ITD-00508-00563\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501191\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:10'),
(19, 1, 'CREATE', 'devices', 36, NULL, '{\"device_unique_id\":\"50-ITD-00508-00577\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201219\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:10'),
(20, 1, 'CREATE', 'devices', 37, NULL, '{\"device_unique_id\":\"50-ITD-00508-00574\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501151\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:11'),
(21, 1, 'CREATE', 'devices', 38, NULL, '{\"device_unique_id\":\"50-ITD-00508-00575\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501145\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:11'),
(22, 1, 'CREATE', 'devices', 39, NULL, '{\"device_unique_id\":\"50-ITD-00508-00576\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501111\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:11'),
(23, 1, 'CREATE', 'devices', 40, NULL, '{\"device_unique_id\":\"50-ITD-00508-00549\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501181\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:11'),
(24, 1, 'CREATE', 'devices', 41, NULL, '{\"device_unique_id\":\"50-ITD-00508-00550\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201210\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:11'),
(25, 1, 'CREATE', 'devices', 42, NULL, '{\"device_unique_id\":\"50-ITD-00508-00557\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201208\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:11'),
(26, 1, 'CREATE', 'devices', 43, NULL, '{\"device_unique_id\":\"50-ITD-00508-00558\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201189\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:12'),
(27, 1, 'CREATE', 'devices', 44, NULL, '{\"device_unique_id\":\"50-ITD-00508-00556\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501190\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:12'),
(28, 1, 'CREATE', 'devices', 45, NULL, '{\"device_unique_id\":\"50-ITD-00508-00573\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501180\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:12'),
(29, 1, 'CREATE', 'devices', 46, NULL, '{\"device_unique_id\":\"50-ITD-00508-00570\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501136\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:12'),
(30, 1, 'CREATE', 'devices', 47, NULL, '{\"device_unique_id\":\"50-ITD-00508-00578\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253201227\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:12'),
(31, 1, 'CREATE', 'devices', 48, NULL, '{\"device_unique_id\":\"50-ITD-00508-00579\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501172\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:12'),
(32, 1, 'CREATE', 'devices', 49, NULL, '{\"device_unique_id\":\"50-ITD-00508-00542\",\"type_id\":\"10\",\"brand_id\":\"22\",\"model\":null,\"serial_number\":\"XZC253501137\",\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-01-15 10:50:12'),
(33, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2026-01-20 07:24:15'),
(34, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36', '2026-01-20 07:45:40'),
(35, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2026-01-20 07:50:13'),
(36, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2026-01-20 07:50:19'),
(37, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2026-01-20 09:44:29'),
(38, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2026-01-20 10:57:01'),
(39, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2026-01-22 10:42:56'),
(40, 1, 'CREATE', 'devices', 50, NULL, '{\"device_unique_id\":\"50-ITD-0514-02592\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"OptiPlex 7090\",\"serial_number\":\"00:68:EB:CA:4E:02\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:01'),
(41, 1, 'CREATE', 'devices', 51, NULL, '{\"device_unique_id\":\"50-ITD-0514-02555\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"EliteBook 840 G8\",\"serial_number\":\"00:68:EB:CA:4D:F7\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:01'),
(42, 1, 'CREATE', 'devices', 52, NULL, '{\"device_unique_id\":\"50-ITD-0514-02670\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"EB-X05\",\"serial_number\":\"6C:02:EO:5F:95:4D\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:01'),
(43, 1, 'CREATE', 'devices', 53, NULL, '{\"device_unique_id\":\"50-ITD-0514-02578\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"S24R350\",\"serial_number\":\"00:68:EB:CA:4B:19\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:02'),
(44, 1, 'CREATE', 'devices', 54, NULL, '{\"device_unique_id\":\"50-ITD-0514-02588\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"PIXMA G3020\",\"serial_number\":\"00:68:EB:CA:8D:51\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:02'),
(45, 1, 'CREATE', 'devices', 55, NULL, '{\"device_unique_id\":\"50-ITD-0514-02619\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"6C:02:E0:5F:98:77\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:02'),
(46, 1, 'CREATE', 'devices', 56, NULL, '{\"device_unique_id\":\"50-ITD-0514-02629\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"6C:02:E0:5F:99:E5\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:02'),
(47, 1, 'CREATE', 'devices', 57, NULL, '{\"device_unique_id\":\"50-ITD-0514-02599\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"00:68:EB:CA:4E:12\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:02'),
(48, 1, 'CREATE', 'devices', 58, NULL, '{\"device_unique_id\":\"50-ITD-0514-02568\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"00:68:EB:B4:F5:38\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:02'),
(49, 1, 'CREATE', 'devices', 59, NULL, '{\"device_unique_id\":\"50-ITD-0514-02664\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"6C:02:E0:5F:95:EE\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:02'),
(50, 1, 'CREATE', 'devices', 60, NULL, '{\"device_unique_id\":\"50-ITD-0514-02673\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"6C:02:E0:5F:97:7C\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:03'),
(51, 1, 'CREATE', 'devices', 61, NULL, '{\"device_unique_id\":\"50-ITD-0514-02669\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"6C:02:E0:5F:98:93\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:03'),
(52, 1, 'CREATE', 'devices', 62, NULL, '{\"device_unique_id\":\"50-ITD-0514-02585\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"00:68:EB:CA:4E:5C\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:03'),
(53, 1, 'CREATE', 'devices', 63, NULL, '{\"device_unique_id\":\"50-ITD-0514-02598\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"00:68:EB:CA:4E:16\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:03'),
(54, 1, 'CREATE', 'devices', 64, NULL, '{\"device_unique_id\":\"50-ITD-0514-02575\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":null,\"serial_number\":\"00:68:EB:CA:4E:61\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 11:29:03'),
(55, 1, 'CREATE', 'device_installations', 5, NULL, '{\"device_id\":\"50\",\"room_id\":\"50\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:38'),
(56, 1, 'CREATE', 'device_installations', 6, NULL, '{\"device_id\":\"51\",\"room_id\":\"14\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:38'),
(57, 1, 'CREATE', 'device_installations', 7, NULL, '{\"device_id\":\"52\",\"room_id\":\"51\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:39'),
(58, 1, 'CREATE', 'device_installations', 8, NULL, '{\"device_id\":\"53\",\"room_id\":\"52\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:39'),
(59, 1, 'CREATE', 'device_installations', 9, NULL, '{\"device_id\":\"54\",\"room_id\":\"53\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:39'),
(60, 1, 'CREATE', 'device_installations', 10, NULL, '{\"device_id\":\"55\",\"room_id\":\"15\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:39'),
(61, 1, 'CREATE', 'device_installations', 11, NULL, '{\"device_id\":\"56\",\"room_id\":\"16\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:39'),
(62, 1, 'CREATE', 'device_installations', 12, NULL, '{\"device_id\":\"57\",\"room_id\":\"54\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:40'),
(63, 1, 'CREATE', 'device_installations', 13, NULL, '{\"device_id\":\"58\",\"room_id\":\"17\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:40'),
(64, 1, 'CREATE', 'device_installations', 14, NULL, '{\"device_id\":\"59\",\"room_id\":\"55\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:40'),
(65, 1, 'CREATE', 'device_installations', 15, NULL, '{\"device_id\":\"60\",\"room_id\":\"56\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:58:40'),
(66, 1, 'CREATE', 'device_installations', 16, NULL, '{\"device_id\":\"61\",\"room_id\":\"18\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:59:23'),
(67, 1, 'CREATE', 'device_installations', 17, NULL, '{\"device_id\":\"62\",\"room_id\":\"19\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:59:23'),
(68, 1, 'CREATE', 'device_installations', 18, NULL, '{\"device_id\":\"63\",\"room_id\":\"57\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:59:23'),
(69, 1, 'CREATE', 'device_installations', 19, NULL, '{\"device_id\":\"64\",\"room_id\":\"58\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 11:59:23'),
(70, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.7462', '2026-01-22 12:07:59'),
(71, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.7462', '2026-01-22 12:08:38'),
(72, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.7462', '2026-01-22 12:10:43'),
(73, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.7462', '2026-01-22 12:13:05'),
(74, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.7462', '2026-01-22 12:18:37'),
(75, 1, 'CREATE', 'devices', 65, NULL, '{\"device_unique_id\":\"50-ITD-0514-02558\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:50\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:00'),
(76, 1, 'CREATE', 'devices', 66, NULL, '{\"device_unique_id\":\"50-ITD-0514-02565\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:60:0A:9E\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:00'),
(77, 1, 'CREATE', 'devices', 67, NULL, '{\"device_unique_id\":\"50-ITD-0514-02626\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:96:FD\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:00'),
(78, 1, 'CREATE', 'devices', 68, NULL, '{\"device_unique_id\":\"50-ITD-0514-02574\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:AF\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:00'),
(79, 1, 'CREATE', 'devices', 69, NULL, '{\"device_unique_id\":\"50-ITD-0514-02666\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:97:5B\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(80, 1, 'CREATE', 'devices', 70, NULL, '{\"device_unique_id\":\"50-ITD-0514-02541\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:51:2C\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(81, 1, 'CREATE', 'devices', 71, NULL, '{\"device_unique_id\":\"50-ITD-0514-02595\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:71\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(82, 1, 'CREATE', 'devices', 72, NULL, '{\"device_unique_id\":\"50-ITD-0514-02570\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:B4\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(83, 1, 'CREATE', 'devices', 73, NULL, '{\"device_unique_id\":\"50-ITD-0514-02573\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4D:CA\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(84, 1, 'CREATE', 'devices', 74, NULL, '{\"device_unique_id\":\"50-ITD-0514-02662\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:98:62\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(85, 1, 'CREATE', 'devices', 75, NULL, '{\"device_unique_id\":\"50-ITD-0514-02556\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:32:AB\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(86, 1, 'CREATE', 'devices', 76, NULL, '{\"device_unique_id\":\"50-ITD-0514-02546\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4D:B0\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:01'),
(87, 1, 'CREATE', 'devices', 77, NULL, '{\"device_unique_id\":\"50-ITD-0514-02642\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:98:10\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:02'),
(88, 1, 'CREATE', 'devices', 78, NULL, '{\"device_unique_id\":\"50-ITD-0514-02667\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:95:76\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:02'),
(89, 1, 'CREATE', 'devices', 79, NULL, '{\"device_unique_id\":\"50-ITD-0514- 02552\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:3E:FE\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:02'),
(90, 1, 'CREATE', 'devices', 80, NULL, '{\"device_unique_id\":\"50-ITD-0514-02543\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:A9\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:02'),
(91, 1, 'CREATE', 'devices', 81, NULL, '{\"device_unique_id\":\"50-ITD-0514-02597\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4D:98\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:02'),
(92, 1, 'CREATE', 'devices', 82, NULL, '{\"device_unique_id\":\"50-ITD-0514-02627\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:96:C5\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:02'),
(93, 1, 'CREATE', 'devices', 83, NULL, '{\"device_unique_id\":\"50-ITD-0514-02577\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:3A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:02'),
(94, 1, 'CREATE', 'devices', 84, NULL, '{\"device_unique_id\":\"50-ITD-0514-02550\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:B1\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(95, 1, 'CREATE', 'devices', 85, NULL, '{\"device_unique_id\":\"50-ITD-0514-02559\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:40:9D\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(96, 1, 'CREATE', 'devices', 86, NULL, '{\"device_unique_id\":\"50-ITD-0514-02665\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:94:49\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(97, 1, 'CREATE', 'devices', 87, NULL, '{\"device_unique_id\":\"50-ITD-0514-02617\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:99:6C\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(98, 1, 'CREATE', 'devices', 88, NULL, '{\"device_unique_id\":\"50-ITD-0514-02547\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:CA\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(99, 1, 'CREATE', 'devices', 89, NULL, '{\"device_unique_id\":\"50-ITD-0514-02674\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:95:27\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(100, 1, 'CREATE', 'devices', 90, NULL, '{\"device_unique_id\":\"50-ITD-0514-02582\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4D:59\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(101, 1, 'CREATE', 'devices', 91, NULL, '{\"device_unique_id\":\"50-ITD-0514-02580\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:60:0B:FD\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:03'),
(102, 1, 'CREATE', 'devices', 92, NULL, '{\"device_unique_id\":\"50-ITD-0514-02606\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"6C:02:E0:5F:99:80\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:04'),
(103, 1, 'CREATE', 'devices', 93, NULL, '{\"device_unique_id\":\"50-ITD-0514-02545\",\"type_id\":\"11\",\"brand_id\":\"23\",\"model\":\"HP\",\"serial_number\":\"00:68:EB:CA:4E:99\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 12:40:04'),
(104, 1, 'CREATE', 'device_installations', 20, NULL, '{\"device_id\":\"65\",\"room_id\":\"59\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:07'),
(105, 1, 'CREATE', 'device_installations', 21, NULL, '{\"device_id\":\"66\",\"room_id\":\"60\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:07'),
(106, 1, 'CREATE', 'device_installations', 22, NULL, '{\"device_id\":\"67\",\"room_id\":\"61\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:07'),
(107, 1, 'CREATE', 'device_installations', 23, NULL, '{\"device_id\":\"68\",\"room_id\":\"62\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:07'),
(108, 1, 'CREATE', 'device_installations', 24, NULL, '{\"device_id\":\"69\",\"room_id\":\"63\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:07'),
(109, 1, 'CREATE', 'device_installations', 25, NULL, '{\"device_id\":\"70\",\"room_id\":\"64\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:08'),
(110, 1, 'CREATE', 'device_installations', 26, NULL, '{\"device_id\":\"71\",\"room_id\":\"20\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:08'),
(111, 1, 'CREATE', 'device_installations', 27, NULL, '{\"device_id\":\"72\",\"room_id\":\"65\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:08'),
(112, 1, 'CREATE', 'device_installations', 28, NULL, '{\"device_id\":\"73\",\"room_id\":\"66\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:08'),
(113, 1, 'CREATE', 'device_installations', 29, NULL, '{\"device_id\":\"74\",\"room_id\":\"21\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:08'),
(114, 1, 'CREATE', 'device_installations', 30, NULL, '{\"device_id\":\"75\",\"room_id\":\"67\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:08'),
(115, 1, 'CREATE', 'device_installations', 31, NULL, '{\"device_id\":\"76\",\"room_id\":\"68\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:09'),
(116, 1, 'CREATE', 'device_installations', 32, NULL, '{\"device_id\":\"77\",\"room_id\":\"69\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:09'),
(117, 1, 'CREATE', 'device_installations', 33, NULL, '{\"device_id\":\"78\",\"room_id\":\"70\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:09'),
(118, 1, 'CREATE', 'device_installations', 34, NULL, '{\"device_id\":\"79\",\"room_id\":\"71\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:09'),
(119, 1, 'CREATE', 'device_installations', 35, NULL, '{\"device_id\":\"80\",\"room_id\":\"22\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:09'),
(120, 1, 'CREATE', 'device_installations', 36, NULL, '{\"device_id\":\"81\",\"room_id\":\"72\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:09'),
(121, 1, 'CREATE', 'device_installations', 37, NULL, '{\"device_id\":\"82\",\"room_id\":\"73\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:10'),
(122, 1, 'CREATE', 'device_installations', 38, NULL, '{\"device_id\":\"83\",\"room_id\":\"74\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:10'),
(123, 1, 'CREATE', 'device_installations', 39, NULL, '{\"device_id\":\"84\",\"room_id\":\"75\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:10'),
(124, 1, 'CREATE', 'device_installations', 40, NULL, '{\"device_id\":\"85\",\"room_id\":\"76\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:10'),
(125, 1, 'CREATE', 'device_installations', 41, NULL, '{\"device_id\":\"86\",\"room_id\":\"77\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:10'),
(126, 1, 'CREATE', 'device_installations', 42, NULL, '{\"device_id\":\"87\",\"room_id\":\"23\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:10'),
(127, 1, 'CREATE', 'device_installations', 43, NULL, '{\"device_id\":\"88\",\"room_id\":\"78\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:11'),
(128, 1, 'CREATE', 'device_installations', 44, NULL, '{\"device_id\":\"89\",\"room_id\":\"79\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:11'),
(129, 1, 'CREATE', 'device_installations', 45, NULL, '{\"device_id\":\"90\",\"room_id\":\"24\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:11'),
(130, 1, 'CREATE', 'device_installations', 46, NULL, '{\"device_id\":\"91\",\"room_id\":\"80\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:11'),
(131, 1, 'CREATE', 'device_installations', 47, NULL, '{\"device_id\":\"92\",\"room_id\":\"81\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:11'),
(132, 1, 'CREATE', 'device_installations', 48, NULL, '{\"device_id\":\"93\",\"room_id\":\"82\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 12:55:11'),
(133, 1, 'CREATE', 'devices', 94, NULL, '{\"device_unique_id\":\"50-LAB-0514-791\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:12'),
(134, 1, 'CREATE', 'devices', 95, NULL, '{\"device_unique_id\":\"50-LAB-514-190\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:12'),
(135, 1, 'CREATE', 'devices', 96, NULL, '{\"device_unique_id\":\"50-LAB-514-125\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:12'),
(136, 1, 'CREATE', 'devices', 97, NULL, '{\"device_unique_id\":\"50-LAB-514-83\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:12'),
(137, 1, 'CREATE', 'devices', 98, NULL, '{\"device_unique_id\":\"50-LAB-514-80\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:12'),
(138, 1, 'CREATE', 'devices', 99, NULL, '{\"device_unique_id\":\"50-ITD-0592-001\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:12'),
(139, 1, 'CREATE', 'devices', 100, NULL, '{\"device_unique_id\":\"50-LAB-514-124\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:12'),
(140, 1, 'CREATE', 'devices', 101, NULL, '{\"device_unique_id\":\"50-LAB-514-173\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:13'),
(141, 1, 'CREATE', 'devices', 102, NULL, '{\"device_unique_id\":\"50-ITD-0592-00181\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:13');
INSERT INTO `audit_log` (`log_id`, `user_id`, `action`, `table_name`, `record_id`, `old_values`, `new_values`, `ip_address`, `user_agent`, `created_at`) VALUES
(142, 1, 'CREATE', 'devices', 103, NULL, '{\"device_unique_id\":\"50-ITD-00592-00155\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:13'),
(143, 1, 'CREATE', 'devices', 104, NULL, '{\"device_unique_id\":\"50-ITD-0592-00043\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:13'),
(144, 1, 'CREATE', 'devices', 105, NULL, '{\"device_unique_id\":\"50-ITD-00592-00157\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:13'),
(145, 1, 'CREATE', 'devices', 106, NULL, '{\"device_unique_id\":\"50-LAB-0514-1396\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:13'),
(146, 1, 'CREATE', 'devices', 107, NULL, '{\"device_unique_id\":\"50-ITD-00592-00158\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(147, 1, 'CREATE', 'devices', 108, NULL, '{\"device_unique_id\":\"50-LAB-0514-123\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(148, 1, 'CREATE', 'devices', 109, NULL, '{\"device_unique_id\":\"50-LAB-514-109\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(149, 1, 'CREATE', 'devices', 110, NULL, '{\"device_unique_id\":\"50-ITD-0514-02173\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(150, 1, 'CREATE', 'devices', 111, NULL, '{\"device_unique_id\":\"50-LAB-514-77\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(151, 1, 'CREATE', 'devices', 112, NULL, '{\"device_unique_id\":\"50-ITD-0514-1337\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(152, 1, 'CREATE', 'devices', 113, NULL, '{\"device_unique_id\":\"50-ITD-0514-137\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(153, 1, 'CREATE', 'devices', 114, NULL, '{\"device_unique_id\":\"50-ITD-0514-1352\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:14'),
(154, 1, 'CREATE', 'devices', 115, NULL, '{\"device_unique_id\":\"SL# 3CQ8050H6W\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:15'),
(155, 1, 'CREATE', 'devices', 116, NULL, '{\"device_unique_id\":\"50-ITD-0514-1301\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:15'),
(156, 1, 'CREATE', 'devices', 117, NULL, '{\"device_unique_id\":\"SL# 3CQ80409HF\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:15'),
(157, 1, 'CREATE', 'devices', 118, NULL, '{\"device_unique_id\":\"SL# 3CQ8050HP3\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:15'),
(158, 1, 'CREATE', 'devices', 119, NULL, '{\"device_unique_id\":\"50-ITD-0514-1349\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:15'),
(159, 1, 'CREATE', 'devices', 120, NULL, '{\"device_unique_id\":\"SL# 3CQ80619D1\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:15'),
(160, 1, 'CREATE', 'devices', 121, NULL, '{\"device_unique_id\":\"50-ITD-0514-1321\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:15'),
(161, 1, 'CREATE', 'devices', 122, NULL, '{\"device_unique_id\":\"50-LAB-514-1318\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(162, 1, 'CREATE', 'devices', 123, NULL, '{\"device_unique_id\":\"50-ITD-0514-1297\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(163, 1, 'CREATE', 'devices', 124, NULL, '{\"device_unique_id\":\"50-ITD-00592-00156\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(164, 1, 'CREATE', 'devices', 125, NULL, '{\"device_unique_id\":\"Sl# 3CQ8042NNM\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(165, 1, 'CREATE', 'devices', 126, NULL, '{\"device_unique_id\":\"50-ITD-0514-02107\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(166, 1, 'CREATE', 'devices', 127, NULL, '{\"device_unique_id\":\"50-ITD-0514-1289\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(167, 1, 'CREATE', 'devices', 128, NULL, '{\"device_unique_id\":\"50-ITD-0514-00177\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(168, 1, 'CREATE', 'devices', 129, NULL, '{\"device_unique_id\":\"Sl# 51717069NN\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:16'),
(169, 1, 'CREATE', 'devices', 130, NULL, '{\"device_unique_id\":\"50-ITD-0592-008\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:17'),
(170, 1, 'CREATE', 'devices', 131, NULL, '{\"device_unique_id\":\"50-ITD-Sl# 3cQ80619B2\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:17'),
(171, 1, 'CREATE', 'devices', 132, NULL, '{\"device_unique_id\":\"50-ITD-0514-1395\",\"type_id\":\"12\",\"brand_id\":\"25\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:17'),
(172, 1, 'CREATE', 'devices', 133, NULL, '{\"device_unique_id\":\"50-EML-0514-1587\",\"type_id\":\"12\",\"brand_id\":\"26\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:17'),
(173, 1, 'CREATE', 'devices', 134, NULL, '{\"device_unique_id\":\"50-ITD-0514-00174\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:17'),
(174, 1, 'CREATE', 'devices', 135, NULL, '{\"device_unique_id\":\"0514-02099\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:17'),
(175, 1, 'CREATE', 'devices', 136, NULL, '{\"device_unique_id\":\"50-ITD-0514-00176\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:17'),
(176, 1, 'CREATE', 'devices', 137, NULL, '{\"device_unique_id\":\"50-ITD-00592-00169\",\"type_id\":\"12\",\"brand_id\":\"24\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 13:12:18'),
(177, 1, 'CREATE', 'device_installations', 49, NULL, '{\"device_id\":\"94\",\"room_id\":\"50\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:33'),
(178, 1, 'CREATE', 'device_installations', 50, NULL, '{\"device_id\":\"95\",\"room_id\":\"14\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:34'),
(179, 1, 'CREATE', 'device_installations', 51, NULL, '{\"device_id\":\"96\",\"room_id\":\"51\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:34'),
(180, 1, 'CREATE', 'device_installations', 52, NULL, '{\"device_id\":\"97\",\"room_id\":\"52\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:34'),
(181, 1, 'CREATE', 'device_installations', 53, NULL, '{\"device_id\":\"98\",\"room_id\":\"53\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:34'),
(182, 1, 'CREATE', 'device_installations', 54, NULL, '{\"device_id\":\"99\",\"room_id\":\"15\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:34'),
(183, 1, 'CREATE', 'device_installations', 55, NULL, '{\"device_id\":\"100\",\"room_id\":\"16\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:35'),
(184, 1, 'CREATE', 'device_installations', 56, NULL, '{\"device_id\":\"101\",\"room_id\":\"54\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:35'),
(185, 1, 'CREATE', 'device_installations', 57, NULL, '{\"device_id\":\"102\",\"room_id\":\"17\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:35'),
(186, 1, 'CREATE', 'device_installations', 58, NULL, '{\"device_id\":\"103\",\"room_id\":\"55\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:35'),
(187, 1, 'CREATE', 'device_installations', 59, NULL, '{\"device_id\":\"104\",\"room_id\":\"56\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:35'),
(188, 1, 'CREATE', 'device_installations', 60, NULL, '{\"device_id\":\"105\",\"room_id\":\"18\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:35'),
(189, 1, 'CREATE', 'device_installations', 61, NULL, '{\"device_id\":\"106\",\"room_id\":\"19\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:36'),
(190, 1, 'CREATE', 'device_installations', 62, NULL, '{\"device_id\":\"107\",\"room_id\":\"57\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:36'),
(191, 1, 'CREATE', 'device_installations', 63, NULL, '{\"device_id\":\"108\",\"room_id\":\"58\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:36'),
(192, 1, 'CREATE', 'device_installations', 64, NULL, '{\"device_id\":\"109\",\"room_id\":\"59\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:36'),
(193, 1, 'CREATE', 'device_installations', 65, NULL, '{\"device_id\":\"110\",\"room_id\":\"60\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:36'),
(194, 1, 'CREATE', 'device_installations', 66, NULL, '{\"device_id\":\"111\",\"room_id\":\"61\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:36'),
(195, 1, 'CREATE', 'device_installations', 67, NULL, '{\"device_id\":\"112\",\"room_id\":\"62\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:37'),
(196, 1, 'CREATE', 'device_installations', 68, NULL, '{\"device_id\":\"113\",\"room_id\":\"63\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:37'),
(197, 1, 'CREATE', 'device_installations', 69, NULL, '{\"device_id\":\"114\",\"room_id\":\"64\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:37'),
(198, 1, 'CREATE', 'device_installations', 70, NULL, '{\"device_id\":\"115\",\"room_id\":\"20\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:37'),
(199, 1, 'CREATE', 'device_installations', 71, NULL, '{\"device_id\":\"116\",\"room_id\":\"65\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:37'),
(200, 1, 'CREATE', 'device_installations', 72, NULL, '{\"device_id\":\"117\",\"room_id\":\"66\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:38'),
(201, 1, 'CREATE', 'device_installations', 73, NULL, '{\"device_id\":\"118\",\"room_id\":\"21\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:38'),
(202, 1, 'CREATE', 'device_installations', 74, NULL, '{\"device_id\":\"119\",\"room_id\":\"67\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:38'),
(203, 1, 'CREATE', 'device_installations', 75, NULL, '{\"device_id\":\"120\",\"room_id\":\"68\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:38'),
(204, 1, 'CREATE', 'device_installations', 76, NULL, '{\"device_id\":\"121\",\"room_id\":\"69\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:38'),
(205, 1, 'CREATE', 'device_installations', 77, NULL, '{\"device_id\":\"122\",\"room_id\":\"70\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:38'),
(206, 1, 'CREATE', 'device_installations', 78, NULL, '{\"device_id\":\"123\",\"room_id\":\"71\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:39'),
(207, 1, 'CREATE', 'device_installations', 79, NULL, '{\"device_id\":\"124\",\"room_id\":\"22\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:39'),
(208, 1, 'CREATE', 'device_installations', 80, NULL, '{\"device_id\":\"125\",\"room_id\":\"72\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:39'),
(209, 1, 'CREATE', 'device_installations', 81, NULL, '{\"device_id\":\"126\",\"room_id\":\"73\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:39'),
(210, 1, 'CREATE', 'device_installations', 82, NULL, '{\"device_id\":\"127\",\"room_id\":\"74\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:39'),
(211, 1, 'CREATE', 'device_installations', 83, NULL, '{\"device_id\":\"128\",\"room_id\":\"75\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:40'),
(212, 1, 'CREATE', 'device_installations', 84, NULL, '{\"device_id\":\"129\",\"room_id\":\"76\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:40'),
(213, 1, 'CREATE', 'device_installations', 85, NULL, '{\"device_id\":\"130\",\"room_id\":\"77\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:40'),
(214, 1, 'CREATE', 'device_installations', 86, NULL, '{\"device_id\":\"131\",\"room_id\":\"23\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:40'),
(215, 1, 'CREATE', 'device_installations', 87, NULL, '{\"device_id\":\"132\",\"room_id\":\"78\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:40'),
(216, 1, 'CREATE', 'device_installations', 88, NULL, '{\"device_id\":\"133\",\"room_id\":\"79\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:40'),
(217, 1, 'CREATE', 'device_installations', 89, NULL, '{\"device_id\":\"134\",\"room_id\":\"24\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:41'),
(218, 1, 'CREATE', 'device_installations', 90, NULL, '{\"device_id\":\"136\",\"room_id\":\"81\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:41'),
(219, 1, 'CREATE', 'device_installations', 91, NULL, '{\"device_id\":\"137\",\"room_id\":\"82\",\"installed_date\":\"12\\/1\\/2022\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-01-22 13:50:41'),
(220, 1, 'SOFT_DELETE', 'devices', 135, NULL, NULL, NULL, NULL, '2026-01-22 13:55:16'),
(221, 1, 'CREATE', 'devices', 138, NULL, '{\"device_unique_id\":\"50-ITD-0514-02099\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"12\\/12\\/2022\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:00:05'),
(222, 1, 'RESTORE', 'devices', 135, NULL, NULL, NULL, NULL, '2026-01-22 14:04:36'),
(223, 1, 'CREATE', 'devices', 139, NULL, '{\"device_unique_id\":\"50-ITD-0508-00481\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VJW243101537\",\"purchase_date\":\"14-Nov-24\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:14'),
(224, 1, 'CREATE', 'devices', 140, NULL, '{\"device_unique_id\":\"50-ITD-0508-00482\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ241801588\",\"purchase_date\":\"14-Nov-24\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:14'),
(225, 1, 'CREATE', 'devices', 141, NULL, '{\"device_unique_id\":\"50-ITD-0508-00485\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ241801261\",\"purchase_date\":\"17-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:14'),
(226, 1, 'CREATE', 'devices', 142, NULL, '{\"device_unique_id\":\"50-ITD-0508-00486\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ243101484\",\"purchase_date\":\"17-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:14'),
(227, 1, 'CREATE', 'devices', 143, NULL, '{\"device_unique_id\":\"50-ITD-0508-00487\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ241501450\",\"purchase_date\":\"17-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:14'),
(228, 1, 'CREATE', 'devices', 144, NULL, '{\"device_unique_id\":\"50-ITD-0508-00488\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ243101478\",\"purchase_date\":\"17-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:14'),
(229, 1, 'CREATE', 'devices', 145, NULL, '{\"device_unique_id\":\"50-ITD-0508-00489\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ243101479\",\"purchase_date\":\"17-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:15'),
(230, 1, 'CREATE', 'devices', 146, NULL, '{\"device_unique_id\":\"50-ITD-0508-00490\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ243101728\",\"purchase_date\":\"29-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:15'),
(231, 1, 'CREATE', 'devices', 147, NULL, '{\"device_unique_id\":\"50-ITD-0508-00491\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ243101469\",\"purchase_date\":\"29-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:15'),
(232, 1, 'CREATE', 'devices', 148, NULL, '{\"device_unique_id\":\"50-ITD-0508-00492\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ243101483\",\"purchase_date\":\"29-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:15'),
(233, 1, 'CREATE', 'devices', 149, NULL, '{\"device_unique_id\":\"50-ITD-0508-00493\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ241801126\",\"purchase_date\":\"29-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:15'),
(234, 1, 'CREATE', 'devices', 150, NULL, '{\"device_unique_id\":\"50-ITD-0508-00494\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"PA503XE\",\"serial_number\":\"VWJ243101888\",\"purchase_date\":\"29-Apr-25\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-01-22 14:14:15'),
(235, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2026-01-27 02:28:17'),
(236, 1, 'CREATE', 'devices', 151, NULL, '{\"device_unique_id\":\"50-ITD-0514-025111\",\"type_id\":\"12\",\"brand_id\":\"23\",\"model\":\"N\\/A\",\"serial_number\":\"\",\"device_status\":\"NEW\",\"current_issue\":null,\"storage_location\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":\"\"}', NULL, NULL, '2026-01-27 02:28:47'),
(237, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.7462', '2026-01-27 03:30:10'),
(238, 1, 'CREATE', 'device_installations', 92, NULL, '{\"device_id\":\"138\",\"room_id\":\"80\",\"installed_date\":\"2022-02-27\",\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":\"\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null}', NULL, NULL, '2026-01-27 13:54:12'),
(239, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2026-02-03 08:35:53'),
(240, 1, 'CREATE', 'devices', 152, NULL, '{\"device_unique_id\":\"50-ITD-0508-00454\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E4010054\",\"purchase_date\":\"30-05-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:04'),
(241, 1, 'CREATE', 'devices', 153, NULL, '{\"device_unique_id\":\"50-ITD-0508-00548\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC253501194\",\"purchase_date\":\"8\\/12\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:04'),
(242, 1, 'CREATE', 'devices', 154, NULL, '{\"device_unique_id\":\"50-ITD-0508-00428\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E3430045\",\"purchase_date\":\"18-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:04'),
(243, 1, 'CREATE', 'devices', 155, NULL, '{\"device_unique_id\":\"50-ITD-0508-00491\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"VWJ243101469\",\"purchase_date\":\"17-05-2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:04'),
(244, 1, 'CREATE', 'devices', 156, NULL, '{\"device_unique_id\":\"50-ITD-0508-00536\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC250301022\",\"purchase_date\":\"23\\/10\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:05'),
(245, 1, 'CREATE', 'devices', 157, NULL, '{\"device_unique_id\":\"50-ITD-0508-00388\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"N\\/A\",\"purchase_date\":\"18-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:05'),
(246, 1, 'CREATE', 'devices', 158, NULL, '{\"device_unique_id\":\"50-ITD-0508-00472\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"N\\/A\",\"purchase_date\":null,\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:05'),
(247, 1, 'CREATE', 'devices', 159, NULL, '{\"device_unique_id\":\"50-ITD-0508-00473\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"N\\/A\",\"purchase_date\":\"N\\/A\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:05'),
(248, 1, 'CREATE', 'devices', 160, NULL, '{\"device_unique_id\":\"50-ITD-0508-00529\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC250301387\",\"purchase_date\":\"23\\/09\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:06'),
(249, 1, 'CREATE', 'devices', 161, NULL, '{\"device_unique_id\":\"50-ITD-0508-00532\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC250301322\",\"purchase_date\":\"23\\/09\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:06'),
(250, 1, 'CREATE', 'devices', 162, NULL, '{\"device_unique_id\":\"50-ITD-0508-00543\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC253201215\",\"purchase_date\":\"1\\/12\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:06'),
(251, 1, 'CREATE', 'devices', 163, NULL, '{\"device_unique_id\":\"50-ITD-0508-00497\",\"type_id\":\"13\",\"brand_id\":\"29\",\"model\":null,\"serial_number\":\"Q7D6450XAAA1B0066\",\"purchase_date\":\"26\\/05\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:06'),
(252, 1, 'CREATE', 'devices', 164, NULL, '{\"device_unique_id\":\"50-ITD-0508-00547\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC253201224\",\"purchase_date\":\"1\\/12\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:06'),
(253, 1, 'CREATE', 'devices', 165, NULL, '{\"device_unique_id\":\"50-ITD-0508-00506\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC250301219\",\"purchase_date\":\"26\\/05\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:06'),
(254, 1, 'CREATE', 'devices', 166, NULL, '{\"device_unique_id\":\"50-ITD-0508-00488\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"VWJ243101478\",\"purchase_date\":\"25\\/04\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:06'),
(255, 1, 'CREATE', 'devices', 167, NULL, '{\"device_unique_id\":\"50-ITD-0508-00413\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E4010036\",\"purchase_date\":\"28-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:07'),
(256, 1, 'CREATE', 'devices', 168, NULL, '{\"device_unique_id\":\"50-ITD-0508-00531\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC245101398\",\"purchase_date\":\"24\\/09\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:07'),
(257, 1, 'CREATE', 'devices', 169, NULL, '{\"device_unique_id\":\"50-ITD-0508-00540\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC250301385\",\"purchase_date\":\"26\\/09\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:07'),
(258, 1, 'CREATE', 'devices', 170, NULL, '{\"device_unique_id\":\"50-ITD-0508-00304\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"N\\/A\",\"purchase_date\":null,\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:07'),
(259, 1, 'CREATE', 'devices', 171, NULL, '{\"device_unique_id\":\"50-ITD-0508-00471\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"N\\/A\",\"purchase_date\":null,\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:07'),
(260, 1, 'CREATE', 'devices', 172, NULL, '{\"device_unique_id\":\"50-ITD-0508-00420\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E4010026\",\"purchase_date\":\"18-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:07'),
(261, 1, 'CREATE', 'devices', 173, NULL, '{\"device_unique_id\":\"50-ITD-0508-00509\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC250301316\",\"purchase_date\":\"26-05-2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:08'),
(262, 1, 'CREATE', 'devices', 174, NULL, '{\"device_unique_id\":\"50-ITD-0508-00487\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"VWJ241501450\",\"purchase_date\":\"25-04-2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:08'),
(263, 1, 'CREATE', 'devices', 175, NULL, '{\"device_unique_id\":\"50-ITD-0508-00424\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E4010023\",\"purchase_date\":\"18-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:08'),
(264, 1, 'CREATE', 'devices', 176, NULL, '{\"device_unique_id\":\"50-ITD-0508-00422\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E3430036\",\"purchase_date\":\"18-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:08'),
(265, 1, 'CREATE', 'devices', 177, NULL, '{\"device_unique_id\":\"50-ITD-0508-00544\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC253201181\",\"purchase_date\":\"1\\/12\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:08'),
(266, 1, 'CREATE', 'devices', 178, NULL, '{\"device_unique_id\":\"50-ITD-0508-00545\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC253501179\",\"purchase_date\":\"1\\/12\\/2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:08'),
(267, 1, 'CREATE', 'devices', 179, NULL, '{\"device_unique_id\":\"50-ITD-0508-00485\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"VWJ241501450\",\"purchase_date\":\"18-04-2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:09'),
(268, 1, 'CREATE', 'devices', 180, NULL, '{\"device_unique_id\":\"50-ITD-0508-00421\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E3430077\",\"purchase_date\":\"18-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:09'),
(269, 1, 'CREATE', 'devices', 181, NULL, '{\"device_unique_id\":\"50-ITD-0508-00546\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC253501193\",\"purchase_date\":\"18-12-2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:09'),
(270, 1, 'CREATE', 'devices', 182, NULL, '{\"device_unique_id\":\"50-ITD-0508-00502\",\"type_id\":\"13\",\"brand_id\":\"29\",\"model\":null,\"serial_number\":\"Q7D6450XAAA1B0015\",\"purchase_date\":\"26-05-2025\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:09'),
(271, 1, 'CREATE', 'devices', 183, NULL, '{\"device_unique_id\":\"50-ITD-00508-00580\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"XZC253501141\",\"purchase_date\":\"22-01-2026\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:09'),
(272, 1, 'CREATE', 'devices', 184, NULL, '{\"device_unique_id\":\"50-ITD-0508-429\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E4010039\",\"purchase_date\":\"19-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:09'),
(273, 1, 'CREATE', 'devices', 185, NULL, '{\"device_unique_id\":\"50-ITD-0508-430\",\"type_id\":\"13\",\"brand_id\":\"28\",\"model\":null,\"serial_number\":\"33130286E4010048\",\"purchase_date\":\"19-02-2024\",\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:10'),
(274, 1, 'CREATE', 'devices', 186, NULL, '{\"device_unique_id\":\"50-ITD-0508-00465\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"N\\/A\",\"purchase_date\":null,\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:10'),
(275, 1, 'CREATE', 'devices', 187, NULL, '{\"device_unique_id\":\"50-ITD-0508-00466\",\"type_id\":\"13\",\"brand_id\":\"27\",\"model\":\"SP7\",\"serial_number\":\"N\\/A\",\"purchase_date\":null,\"warranty_period\":\"36\",\"notes\":null}', NULL, NULL, '2026-02-03 09:39:10'),
(276, 1, 'CREATE', 'device_installations', 93, NULL, '{\"device_id\":\"152\",\"room_id\":\"50\",\"installed_date\":\"30-05-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:49'),
(277, 1, 'CREATE', 'device_installations', 94, NULL, '{\"device_id\":\"18\",\"room_id\":\"14\",\"installed_date\":\"3\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:49');
INSERT INTO `audit_log` (`log_id`, `user_id`, `action`, `table_name`, `record_id`, `old_values`, `new_values`, `ip_address`, `user_agent`, `created_at`) VALUES
(278, 1, 'CREATE', 'device_installations', 95, NULL, '{\"device_id\":\"153\",\"room_id\":\"51\",\"installed_date\":\"8\\/12\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:49'),
(279, 1, 'CREATE', 'device_installations', 96, NULL, '{\"device_id\":\"154\",\"room_id\":\"52\",\"installed_date\":\"18-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:50'),
(280, 1, 'CREATE', 'device_installations', 97, NULL, '{\"device_id\":\"155\",\"room_id\":\"53\",\"installed_date\":\"17-05-2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:50'),
(281, 1, 'CREATE', 'device_installations', 98, NULL, '{\"device_id\":\"19\",\"room_id\":\"15\",\"installed_date\":\"3\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:50'),
(282, 1, 'CREATE', 'device_installations', 99, NULL, '{\"device_id\":\"20\",\"room_id\":\"16\",\"installed_date\":\"3\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:50'),
(283, 1, 'CREATE', 'device_installations', 100, NULL, '{\"device_id\":\"156\",\"room_id\":\"54\",\"installed_date\":\"23\\/10\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:50'),
(284, 1, 'CREATE', 'device_installations', 101, NULL, '{\"device_id\":\"21\",\"room_id\":\"17\",\"installed_date\":\"3\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:51'),
(285, 1, 'CREATE', 'device_installations', 102, NULL, '{\"device_id\":\"157\",\"room_id\":\"55\",\"installed_date\":\"18-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:51'),
(286, 1, 'CREATE', 'device_installations', 103, NULL, '{\"device_id\":\"158\",\"room_id\":\"56\",\"installed_date\":\"23\\/10\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:51'),
(287, 1, 'CREATE', 'device_installations', 104, NULL, '{\"device_id\":\"159\",\"room_id\":\"56\",\"installed_date\":\"23\\/10\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:51'),
(288, 1, 'CREATE', 'device_installations', 105, NULL, '{\"device_id\":\"22\",\"room_id\":\"18\",\"installed_date\":\"3\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:51'),
(289, 1, 'CREATE', 'device_installations', 106, NULL, '{\"device_id\":\"23\",\"room_id\":\"19\",\"installed_date\":\"6\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:51'),
(290, 1, 'CREATE', 'device_installations', 107, NULL, '{\"device_id\":\"160\",\"room_id\":\"57\",\"installed_date\":\"23\\/09\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:52'),
(291, 1, 'CREATE', 'device_installations', 108, NULL, '{\"device_id\":\"161\",\"room_id\":\"58\",\"installed_date\":\"23\\/09\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:52'),
(292, 1, 'CREATE', 'device_installations', 109, NULL, '{\"device_id\":\"162\",\"room_id\":\"59\",\"installed_date\":\"1\\/12\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:52'),
(293, 1, 'CREATE', 'device_installations', 110, NULL, '{\"device_id\":\"163\",\"room_id\":\"60\",\"installed_date\":\"26\\/05\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:52'),
(294, 1, 'CREATE', 'device_installations', 111, NULL, '{\"device_id\":\"164\",\"room_id\":\"61\",\"installed_date\":\"1\\/12\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:52'),
(295, 1, 'CREATE', 'device_installations', 112, NULL, '{\"device_id\":\"165\",\"room_id\":\"62\",\"installed_date\":\"26\\/05\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:53'),
(296, 1, 'CREATE', 'device_installations', 113, NULL, '{\"device_id\":\"166\",\"room_id\":\"63\",\"installed_date\":\"25\\/04\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:53'),
(297, 1, 'CREATE', 'device_installations', 114, NULL, '{\"device_id\":\"167\",\"room_id\":\"64\",\"installed_date\":\"28-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:53'),
(298, 1, 'CREATE', 'device_installations', 115, NULL, '{\"device_id\":\"24\",\"room_id\":\"20\",\"installed_date\":\"6\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:53'),
(299, 1, 'CREATE', 'device_installations', 116, NULL, '{\"device_id\":\"168\",\"room_id\":\"65\",\"installed_date\":\"24\\/09\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:53'),
(300, 1, 'CREATE', 'device_installations', 117, NULL, '{\"device_id\":\"169\",\"room_id\":\"66\",\"installed_date\":\"26\\/09\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:53'),
(301, 1, 'CREATE', 'device_installations', 118, NULL, '{\"device_id\":\"25\",\"room_id\":\"21\",\"installed_date\":\"6\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:54'),
(302, 1, 'CREATE', 'device_installations', 119, NULL, '{\"device_id\":\"170\",\"room_id\":\"67\",\"installed_date\":\"23\\/10\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:54'),
(303, 1, 'CREATE', 'device_installations', 120, NULL, '{\"device_id\":\"171\",\"room_id\":\"67\",\"installed_date\":\"23\\/10\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:54'),
(304, 1, 'CREATE', 'device_installations', 121, NULL, '{\"device_id\":\"172\",\"room_id\":\"68\",\"installed_date\":\"18-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:54'),
(305, 1, 'CREATE', 'device_installations', 122, NULL, '{\"device_id\":\"173\",\"room_id\":\"69\",\"installed_date\":\"26-05-2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:54'),
(306, 1, 'CREATE', 'device_installations', 123, NULL, '{\"device_id\":\"174\",\"room_id\":\"70\",\"installed_date\":\"25-04-2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:55'),
(307, 1, 'CREATE', 'device_installations', 124, NULL, '{\"device_id\":\"175\",\"room_id\":\"71\",\"installed_date\":\"18-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:55'),
(308, 1, 'CREATE', 'device_installations', 125, NULL, '{\"device_id\":\"26\",\"room_id\":\"22\",\"installed_date\":\"6\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:55'),
(309, 1, 'CREATE', 'device_installations', 126, NULL, '{\"device_id\":\"176\",\"room_id\":\"72\",\"installed_date\":\"18-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:55'),
(310, 1, 'CREATE', 'device_installations', 127, NULL, '{\"device_id\":\"177\",\"room_id\":\"73\",\"installed_date\":\"1\\/12\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:55'),
(311, 1, 'CREATE', 'device_installations', 128, NULL, '{\"device_id\":\"178\",\"room_id\":\"74\",\"installed_date\":\"1\\/12\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:56'),
(312, 1, 'CREATE', 'device_installations', 129, NULL, '{\"device_id\":\"179\",\"room_id\":\"75\",\"installed_date\":\"18-04-2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:56'),
(313, 1, 'CREATE', 'device_installations', 130, NULL, '{\"device_id\":\"180\",\"room_id\":\"76\",\"installed_date\":\"18-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:56'),
(314, 1, 'CREATE', 'device_installations', 131, NULL, '{\"device_id\":\"181\",\"room_id\":\"77\",\"installed_date\":\"18-12-2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:56'),
(315, 1, 'CREATE', 'device_installations', 132, NULL, '{\"device_id\":\"27\",\"room_id\":\"23\",\"installed_date\":\"6\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:56'),
(316, 1, 'CREATE', 'device_installations', 133, NULL, '{\"device_id\":\"182\",\"room_id\":\"78\",\"installed_date\":\"26-05-2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:56'),
(317, 1, 'CREATE', 'device_installations', 134, NULL, '{\"device_id\":\"183\",\"room_id\":\"79\",\"installed_date\":\"22-01-2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:57'),
(318, 1, 'CREATE', 'device_installations', 135, NULL, '{\"device_id\":\"28\",\"room_id\":\"24\",\"installed_date\":\"6\\/1\\/2026\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:57'),
(319, 1, 'CREATE', 'device_installations', 136, NULL, '{\"device_id\":\"184\",\"room_id\":\"80\",\"installed_date\":\"19-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:57'),
(320, 1, 'CREATE', 'device_installations', 137, NULL, '{\"device_id\":\"185\",\"room_id\":\"81\",\"installed_date\":\"19-02-2024\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:57'),
(321, 1, 'CREATE', 'device_installations', 138, NULL, '{\"device_id\":\"186\",\"room_id\":\"82\",\"installed_date\":\"23\\/10\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:57'),
(322, 1, 'CREATE', 'device_installations', 139, NULL, '{\"device_id\":\"187\",\"room_id\":\"82\",\"installed_date\":\"23\\/10\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 09:45:58'),
(323, 1, 'CREATE', 'devices', 188, NULL, '{\"device_unique_id\":\"U001\",\"type_id\":\"14\",\"brand_id\":\"30\",\"model\":\"Manual\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:26'),
(324, 1, 'CREATE', 'devices', 189, NULL, '{\"device_unique_id\":\"U002\",\"type_id\":\"14\",\"brand_id\":\"30\",\"model\":\"Manual\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:26'),
(325, 1, 'CREATE', 'devices', 190, NULL, '{\"device_unique_id\":\"50-ITD-0510-0231\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:26'),
(326, 1, 'CREATE', 'devices', 191, NULL, '{\"device_unique_id\":\"U003\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:27'),
(327, 1, 'CREATE', 'devices', 192, NULL, '{\"device_unique_id\":\"50-ITD-0510-00262\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:27'),
(328, 1, 'CREATE', 'devices', 193, NULL, '{\"device_unique_id\":\"U004\",\"type_id\":\"14\",\"brand_id\":\"30\",\"model\":\"Manual\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:27'),
(329, 1, 'CREATE', 'devices', 194, NULL, '{\"device_unique_id\":\"U005\",\"type_id\":\"14\",\"brand_id\":\"30\",\"model\":\"Manual\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:27'),
(330, 1, 'CREATE', 'devices', 195, NULL, '{\"device_unique_id\":\"50-ITD-00510-00267\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:27'),
(331, 1, 'CREATE', 'devices', 196, NULL, '{\"device_unique_id\":\"U006\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:27'),
(332, 1, 'CREATE', 'devices', 197, NULL, '{\"device_unique_id\":\"50-ITD-0510-00269\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:27'),
(333, 1, 'CREATE', 'devices', 198, NULL, '{\"device_unique_id\":\"U007\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:28'),
(334, 1, 'CREATE', 'devices', 199, NULL, '{\"device_unique_id\":\"U008\",\"type_id\":\"14\",\"brand_id\":\"32\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:28'),
(335, 1, 'CREATE', 'devices', 200, NULL, '{\"device_unique_id\":\"50-ITD-00510-00335\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:28'),
(336, 1, 'CREATE', 'devices', 201, NULL, '{\"device_unique_id\":\"U009\",\"type_id\":\"14\",\"brand_id\":\"33\",\"model\":\"Manual\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:28'),
(337, 1, 'CREATE', 'devices', 202, NULL, '{\"device_unique_id\":\"U0010\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:28'),
(338, 1, 'CREATE', 'devices', 203, NULL, '{\"device_unique_id\":\"U0011\",\"type_id\":\"14\",\"brand_id\":\"34\",\"model\":\"Manual\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:28'),
(339, 1, 'CREATE', 'devices', 204, NULL, '{\"device_unique_id\":\"50-ITD-00510-00338\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:28'),
(340, 1, 'CREATE', 'devices', 205, NULL, '{\"device_unique_id\":\"50-ITD-00510-00337\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(341, 1, 'CREATE', 'devices', 206, NULL, '{\"device_unique_id\":\"U12\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(342, 1, 'CREATE', 'devices', 207, NULL, '{\"device_unique_id\":\"U13\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(343, 1, 'CREATE', 'devices', 208, NULL, '{\"device_unique_id\":\"U14\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"MANUAL\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(344, 1, 'CREATE', 'devices', 209, NULL, '{\"device_unique_id\":\"U15\",\"type_id\":\"14\",\"brand_id\":\"30\",\"model\":\"MANUAL\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(345, 1, 'CREATE', 'devices', 210, NULL, '{\"device_unique_id\":\"50-ITD-00510-00336\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(346, 1, 'CREATE', 'devices', 211, NULL, '{\"device_unique_id\":\"U16\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(347, 1, 'CREATE', 'devices', 212, NULL, '{\"device_unique_id\":\"U17\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:29'),
(348, 1, 'CREATE', 'devices', 213, NULL, '{\"device_unique_id\":\"U18\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(349, 1, 'CREATE', 'devices', 214, NULL, '{\"device_unique_id\":\"U19\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(350, 1, 'CREATE', 'devices', 215, NULL, '{\"device_unique_id\":\"U20\",\"type_id\":\"14\",\"brand_id\":\"35\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(351, 1, 'CREATE', 'devices', 216, NULL, '{\"device_unique_id\":\"U21\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(352, 1, 'CREATE', 'devices', 217, NULL, '{\"device_unique_id\":\"50-ITD-00510-00339\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(353, 1, 'CREATE', 'devices', 218, NULL, '{\"device_unique_id\":\"U22\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(354, 1, 'CREATE', 'devices', 219, NULL, '{\"device_unique_id\":\"50-ITD-0510-099\",\"type_id\":\"14\",\"brand_id\":\"35\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(355, 1, 'CREATE', 'devices', 220, NULL, '{\"device_unique_id\":\"U23\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:30'),
(356, 1, 'CREATE', 'devices', 221, NULL, '{\"device_unique_id\":\"U24\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:31'),
(357, 1, 'CREATE', 'devices', 222, NULL, '{\"device_unique_id\":\"U25\",\"type_id\":\"14\",\"brand_id\":\"35\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:31'),
(358, 1, 'CREATE', 'devices', 223, NULL, '{\"device_unique_id\":\"U26\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:31'),
(359, 1, 'CREATE', 'devices', 224, NULL, '{\"device_unique_id\":\"50-ITD-00510-00340\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:31'),
(360, 1, 'CREATE', 'devices', 225, NULL, '{\"device_unique_id\":\"U27\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:31'),
(361, 1, 'CREATE', 'devices', 226, NULL, '{\"device_unique_id\":\"50-ITD-00510-00341\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:31'),
(362, 1, 'CREATE', 'devices', 227, NULL, '{\"device_unique_id\":\"U28\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:31'),
(363, 1, 'CREATE', 'devices', 228, NULL, '{\"device_unique_id\":\"U29\",\"type_id\":\"14\",\"brand_id\":\"30\",\"model\":\"Manual\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:32'),
(364, 1, 'CREATE', 'devices', 229, NULL, '{\"device_unique_id\":\"U30\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:32'),
(365, 1, 'CREATE', 'devices', 230, NULL, '{\"device_unique_id\":\"U31\",\"type_id\":\"14\",\"brand_id\":\"35\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:32'),
(366, 1, 'CREATE', 'devices', 231, NULL, '{\"device_unique_id\":\"U32\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:17:32'),
(367, 1, 'CREATE', 'devices', 232, NULL, '{\"device_unique_id\":\"U33\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:31:00'),
(368, 1, 'CREATE', 'devices', 233, NULL, '{\"device_unique_id\":\"U34\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:31:00'),
(369, 1, 'CREATE', 'devices', 234, NULL, '{\"device_unique_id\":\"U35\",\"type_id\":\"14\",\"brand_id\":\"31\",\"model\":\"Auto\",\"serial_number\":null,\"purchase_date\":null,\"warranty_period\":null,\"notes\":null}', NULL, NULL, '2026-02-03 11:31:01'),
(370, 1, 'CREATE', 'device_installations', 140, NULL, '{\"device_id\":\"188\",\"room_id\":\"50\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:33'),
(371, 1, 'CREATE', 'device_installations', 141, NULL, '{\"device_id\":\"189\",\"room_id\":\"14\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:33'),
(372, 1, 'CREATE', 'device_installations', 142, NULL, '{\"device_id\":\"190\",\"room_id\":\"51\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:33'),
(373, 1, 'CREATE', 'device_installations', 143, NULL, '{\"device_id\":\"191\",\"room_id\":\"52\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:33'),
(374, 1, 'CREATE', 'device_installations', 144, NULL, '{\"device_id\":\"192\",\"room_id\":\"53\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:34'),
(375, 1, 'CREATE', 'device_installations', 145, NULL, '{\"device_id\":\"193\",\"room_id\":\"15\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:34'),
(376, 1, 'CREATE', 'device_installations', 146, NULL, '{\"device_id\":\"194\",\"room_id\":\"16\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:34'),
(377, 1, 'CREATE', 'device_installations', 147, NULL, '{\"device_id\":\"195\",\"room_id\":\"54\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:34'),
(378, 1, 'CREATE', 'device_installations', 148, NULL, '{\"device_id\":\"196\",\"room_id\":\"17\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:34'),
(379, 1, 'CREATE', 'device_installations', 149, NULL, '{\"device_id\":\"197\",\"room_id\":\"55\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:34'),
(380, 1, 'CREATE', 'device_installations', 150, NULL, '{\"device_id\":\"198\",\"room_id\":\"56\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:35'),
(381, 1, 'CREATE', 'device_installations', 151, NULL, '{\"device_id\":\"199\",\"room_id\":\"56\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:35'),
(382, 1, 'CREATE', 'device_installations', 152, NULL, '{\"device_id\":\"200\",\"room_id\":\"18\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:35'),
(383, 1, 'CREATE', 'device_installations', 153, NULL, '{\"device_id\":\"201\",\"room_id\":\"19\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:35'),
(384, 1, 'CREATE', 'device_installations', 154, NULL, '{\"device_id\":\"202\",\"room_id\":\"57\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:35'),
(385, 1, 'CREATE', 'device_installations', 155, NULL, '{\"device_id\":\"203\",\"room_id\":\"58\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:36'),
(386, 1, 'CREATE', 'device_installations', 156, NULL, '{\"device_id\":\"204\",\"room_id\":\"59\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:36'),
(387, 1, 'CREATE', 'device_installations', 157, NULL, '{\"device_id\":\"205\",\"room_id\":\"60\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:36'),
(388, 1, 'CREATE', 'device_installations', 158, NULL, '{\"device_id\":\"206\",\"room_id\":\"61\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:36'),
(389, 1, 'CREATE', 'device_installations', 159, NULL, '{\"device_id\":\"207\",\"room_id\":\"62\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:36'),
(390, 1, 'CREATE', 'device_installations', 160, NULL, '{\"device_id\":\"208\",\"room_id\":\"63\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:37'),
(391, 1, 'CREATE', 'device_installations', 161, NULL, '{\"device_id\":\"209\",\"room_id\":\"64\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:37'),
(392, 1, 'CREATE', 'device_installations', 162, NULL, '{\"device_id\":\"210\",\"room_id\":\"20\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:37'),
(393, 1, 'CREATE', 'device_installations', 163, NULL, '{\"device_id\":\"211\",\"room_id\":\"65\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:37'),
(394, 1, 'CREATE', 'device_installations', 164, NULL, '{\"device_id\":\"212\",\"room_id\":\"66\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:37');
INSERT INTO `audit_log` (`log_id`, `user_id`, `action`, `table_name`, `record_id`, `old_values`, `new_values`, `ip_address`, `user_agent`, `created_at`) VALUES
(395, 1, 'CREATE', 'device_installations', 165, NULL, '{\"device_id\":\"213\",\"room_id\":\"21\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:37'),
(396, 1, 'CREATE', 'device_installations', 166, NULL, '{\"device_id\":\"214\",\"room_id\":\"67\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:38'),
(397, 1, 'CREATE', 'device_installations', 167, NULL, '{\"device_id\":\"215\",\"room_id\":\"67\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:38'),
(398, 1, 'CREATE', 'device_installations', 168, NULL, '{\"device_id\":\"216\",\"room_id\":\"68\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:38'),
(399, 1, 'CREATE', 'device_installations', 169, NULL, '{\"device_id\":\"217\",\"room_id\":\"69\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:38'),
(400, 1, 'CREATE', 'device_installations', 170, NULL, '{\"device_id\":\"218\",\"room_id\":\"70\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:38'),
(401, 1, 'CREATE', 'device_installations', 171, NULL, '{\"device_id\":\"219\",\"room_id\":\"71\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:39'),
(402, 1, 'CREATE', 'device_installations', 172, NULL, '{\"device_id\":\"220\",\"room_id\":\"22\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:39'),
(403, 1, 'CREATE', 'device_installations', 173, NULL, '{\"device_id\":\"221\",\"room_id\":\"72\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:39'),
(404, 1, 'CREATE', 'device_installations', 174, NULL, '{\"device_id\":\"222\",\"room_id\":\"73\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:39'),
(405, 1, 'CREATE', 'device_installations', 175, NULL, '{\"device_id\":\"223\",\"room_id\":\"74\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:39'),
(406, 1, 'CREATE', 'device_installations', 176, NULL, '{\"device_id\":\"224\",\"room_id\":\"75\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:40'),
(407, 1, 'CREATE', 'device_installations', 177, NULL, '{\"device_id\":\"225\",\"room_id\":\"76\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:40'),
(408, 1, 'CREATE', 'device_installations', 178, NULL, '{\"device_id\":\"226\",\"room_id\":\"77\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:40'),
(409, 1, 'CREATE', 'device_installations', 179, NULL, '{\"device_id\":\"227\",\"room_id\":\"23\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:40'),
(410, 1, 'CREATE', 'device_installations', 180, NULL, '{\"device_id\":\"228\",\"room_id\":\"78\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:40'),
(411, 1, 'CREATE', 'device_installations', 181, NULL, '{\"device_id\":\"229\",\"room_id\":\"79\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:41'),
(412, 1, 'CREATE', 'device_installations', 182, NULL, '{\"device_id\":\"230\",\"room_id\":\"24\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:41'),
(413, 1, 'CREATE', 'device_installations', 183, NULL, '{\"device_id\":\"231\",\"room_id\":\"80\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:41'),
(414, 1, 'CREATE', 'device_installations', 184, NULL, '{\"device_id\":\"232\",\"room_id\":\"81\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:41'),
(415, 1, 'CREATE', 'device_installations', 185, NULL, '{\"device_id\":\"233\",\"room_id\":\"82\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:41'),
(416, 1, 'CREATE', 'device_installations', 186, NULL, '{\"device_id\":\"234\",\"room_id\":\"82\",\"installed_date\":\"10\\/2\\/2025\",\"installer_name\":null,\"installer_id\":null,\"team_members\":null,\"installation_type\":\"NEW_INSTALLATION\",\"installation_notes\":null,\"withdrawn_date\":null,\"withdrawer_name\":null,\"withdrawer_id\":null,\"withdrawal_notes\":null,\"issue_at_withdrawal\":null,\"storage_location\":null,\"gate_pass_number\":null,\"gate_pass_date\":null,\"status\":\"active\"}', NULL, NULL, '2026-02-03 11:34:41'),
(417, 1, 'LOGIN', 'users', 1, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2026-02-07 13:34:16');

-- --------------------------------------------------------

--
-- Table structure for table `blog_categories`
--

CREATE TABLE `blog_categories` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(100) NOT NULL,
  `category_slug` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blog_comments`
--

CREATE TABLE `blog_comments` (
  `comment_id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `parent_comment_id` int(11) DEFAULT NULL,
  `comment_text` text NOT NULL,
  `is_deleted` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blog_posts`
--

CREATE TABLE `blog_posts` (
  `post_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `excerpt` varchar(500) DEFAULT NULL,
  `category_id` int(11) DEFAULT NULL,
  `author_id` int(11) NOT NULL,
  `featured_image` varchar(255) DEFAULT NULL,
  `status` enum('draft','published','archived') DEFAULT 'draft',
  `view_count` int(11) DEFAULT 0,
  `is_pinned` tinyint(1) DEFAULT 0,
  `published_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blog_reactions`
--

CREATE TABLE `blog_reactions` (
  `reaction_id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `reaction_type` enum('like','love','celebrate','insightful') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `classroom_support_records`
--

CREATE TABLE `classroom_support_records` (
  `support_id` int(11) NOT NULL,
  `member_id` int(11) NOT NULL COMMENT 'Support team member who provided support',
  `support_date` date NOT NULL,
  `support_time` time NOT NULL,
  `location` varchar(100) NOT NULL COMMENT 'Classroom number/location',
  `room_id` int(11) DEFAULT NULL COMMENT 'Optional link to rooms table',
  `support_description` text NOT NULL,
  `issue_type` enum('TECHNICAL','SETUP','TRAINING','MAINTENANCE','OTHER') DEFAULT 'TECHNICAL',
  `priority` enum('LOW','MEDIUM','HIGH','URGENT') DEFAULT 'MEDIUM',
  `status` enum('COMPLETED','IN_PROGRESS','PENDING','CANCELLED') DEFAULT 'COMPLETED',
  `devices_involved` text DEFAULT NULL COMMENT 'Comma-separated device IDs if applicable',
  `duration_minutes` int(11) DEFAULT NULL COMMENT 'Duration of support in minutes',
  `faculty_name` varchar(100) DEFAULT NULL COMMENT 'Faculty/staff who requested support',
  `notes` text DEFAULT NULL,
  `created_by` int(11) NOT NULL COMMENT 'User who created this record',
  `is_deleted` tinyint(1) DEFAULT 0,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Records of classroom support activities';

--
-- Triggers `classroom_support_records`
--
DELIMITER $$
CREATE TRIGGER `trg_support_audit_insert` AFTER INSERT ON `classroom_support_records` FOR EACH ROW BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, new_values)
    VALUES (
        NEW.created_by,
        'CREATE',
        'classroom_support_records',
        NEW.support_id,
        JSON_OBJECT(
            'member_id', NEW.member_id,
            'support_date', NEW.support_date,
            'location', NEW.location,
            'support_description', NEW.support_description
        )
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_support_audit_update` AFTER UPDATE ON `classroom_support_records` FOR EACH ROW BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values)
    VALUES (
        NEW.created_by,
        'UPDATE',
        'classroom_support_records',
        NEW.support_id,
        JSON_OBJECT(
            'member_id', OLD.member_id,
            'support_date', OLD.support_date,
            'location', OLD.location,
            'support_description', OLD.support_description
        ),
        JSON_OBJECT(
            'member_id', NEW.member_id,
            'support_date', NEW.support_date,
            'location', NEW.location,
            'support_description', NEW.support_description
        )
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `devices`
--

CREATE TABLE `devices` (
  `device_id` int(11) NOT NULL,
  `device_unique_id` varchar(100) NOT NULL,
  `type_id` int(11) NOT NULL,
  `brand_id` int(11) NOT NULL,
  `model` varchar(100) DEFAULT NULL,
  `device_status` enum('NEW','REPAIR','USED','WITHDRAWN') DEFAULT 'NEW',
  `current_issue` varchar(255) DEFAULT NULL COMMENT 'Current issue like Lamp Damage, Poor Focus, etc.',
  `storage_location` varchar(100) DEFAULT NULL COMMENT 'Storage location like Basement, IT, WARREN Memo',
  `serial_number` varchar(100) DEFAULT NULL COMMENT 'Manufacturer Serial Number (Manufacture SL in Excel)',
  `purchase_date` date DEFAULT NULL,
  `warranty_period` int(11) DEFAULT NULL COMMENT 'Warranty period in months',
  `notes` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_deleted` tinyint(1) DEFAULT 0,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `devices`
--

INSERT INTO `devices` (`device_id`, `device_unique_id`, `type_id`, `brand_id`, `model`, `device_status`, `current_issue`, `storage_location`, `serial_number`, `purchase_date`, `warranty_period`, `notes`, `is_active`, `is_deleted`, `deleted_at`, `deleted_by`, `created_at`, `updated_at`) VALUES
(18, '50-ITD-00508-00553', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201217', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:07', '2026-01-15 10:50:07'),
(19, '50-ITD-00508-00564', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC25350185', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:08', '2026-01-15 10:50:08'),
(20, '50-ITD-00508-00565', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201221', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:08', '2026-01-15 10:50:08'),
(21, '50-ITD-00508-00555', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501067', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:08', '2026-01-15 10:50:08'),
(22, '50-ITD-00508-00566', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501170', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:08', '2026-01-15 10:50:08'),
(23, '50-ITD-00508-00554', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201199', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:08', '2026-01-15 10:50:08'),
(24, '50-ITD-00508-00567', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201200', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:08', '2026-01-15 10:50:08'),
(25, '50-ITD-00508-00568', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201191', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:08', '2026-01-15 10:50:08'),
(26, '50-ITD-00508-00571', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501148', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:09', '2026-01-15 10:50:09'),
(27, '50-ITD-00508-00569', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201222', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:09', '2026-01-15 10:50:09'),
(28, '50-ITD-00508-00572', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501139', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:09', '2026-01-15 10:50:09'),
(29, '50-ITD-00508-00552', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501178', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:09', '2026-01-15 10:50:09'),
(30, '50-ITD-00508-00551', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501165', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:09', '2026-01-15 10:50:09'),
(31, '50-ITD-00508-00559', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501146', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:10', '2026-01-15 10:50:10'),
(32, '50-ITD-00508-00560', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501167', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:10', '2026-01-15 10:50:10'),
(33, '50-ITD-00508-00561', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201216', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:10', '2026-01-15 10:50:10'),
(34, '50-ITD-00508-00562', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201233', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:10', '2026-01-15 10:50:10'),
(35, '50-ITD-00508-00563', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501191', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:10', '2026-01-15 10:50:10'),
(36, '50-ITD-00508-00577', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201219', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:10', '2026-01-15 10:50:10'),
(37, '50-ITD-00508-00574', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501151', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:11', '2026-01-15 10:50:11'),
(38, '50-ITD-00508-00575', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501145', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:11', '2026-01-15 10:50:11'),
(39, '50-ITD-00508-00576', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501111', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:11', '2026-01-15 10:50:11'),
(40, '50-ITD-00508-00549', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501181', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:11', '2026-01-15 10:50:11'),
(41, '50-ITD-00508-00550', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201210', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:11', '2026-01-15 10:50:11'),
(42, '50-ITD-00508-00557', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201208', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:11', '2026-01-15 10:50:11'),
(43, '50-ITD-00508-00558', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201189', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12'),
(44, '50-ITD-00508-00556', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501190', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12'),
(45, '50-ITD-00508-00573', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501180', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12'),
(46, '50-ITD-00508-00570', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501136', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12'),
(47, '50-ITD-00508-00578', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253201227', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12'),
(48, '50-ITD-00508-00579', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501172', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12'),
(49, '50-ITD-00508-00542', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501137', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12'),
(50, '50-ITD-0514-02592', 11, 23, 'OptiPlex 7090', 'NEW', NULL, NULL, '00:68:EB:CA:4E:02', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:01', '2026-01-22 11:29:01'),
(51, '50-ITD-0514-02555', 11, 23, 'EliteBook 840 G8', 'NEW', NULL, NULL, '00:68:EB:CA:4D:F7', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:01', '2026-01-22 11:29:01'),
(52, '50-ITD-0514-02670', 11, 23, 'EB-X05', 'NEW', NULL, NULL, '6C:02:EO:5F:95:4D', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:01', '2026-01-22 11:29:01'),
(53, '50-ITD-0514-02578', 11, 23, 'S24R350', 'NEW', NULL, NULL, '00:68:EB:CA:4B:19', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:02', '2026-01-22 11:29:02'),
(54, '50-ITD-0514-02588', 11, 23, 'PIXMA G3020', 'NEW', NULL, NULL, '00:68:EB:CA:8D:51', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:02', '2026-01-22 11:29:02'),
(55, '50-ITD-0514-02619', 11, 23, NULL, 'NEW', NULL, NULL, '6C:02:E0:5F:98:77', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:02', '2026-01-22 11:29:02'),
(56, '50-ITD-0514-02629', 11, 23, NULL, 'NEW', NULL, NULL, '6C:02:E0:5F:99:E5', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:02', '2026-01-22 11:29:02'),
(57, '50-ITD-0514-02599', 11, 23, NULL, 'NEW', NULL, NULL, '00:68:EB:CA:4E:12', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:02', '2026-01-22 11:29:02'),
(58, '50-ITD-0514-02568', 11, 23, NULL, 'NEW', NULL, NULL, '00:68:EB:B4:F5:38', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:02', '2026-01-22 11:29:02'),
(59, '50-ITD-0514-02664', 11, 23, NULL, 'NEW', NULL, NULL, '6C:02:E0:5F:95:EE', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:02', '2026-01-22 11:29:02'),
(60, '50-ITD-0514-02673', 11, 23, NULL, 'NEW', NULL, NULL, '6C:02:E0:5F:97:7C', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:03', '2026-01-22 11:29:03'),
(61, '50-ITD-0514-02669', 11, 23, NULL, 'NEW', NULL, NULL, '6C:02:E0:5F:98:93', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:03', '2026-01-22 11:29:03'),
(62, '50-ITD-0514-02585', 11, 23, NULL, 'NEW', NULL, NULL, '00:68:EB:CA:4E:5C', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:03', '2026-01-22 11:29:03'),
(63, '50-ITD-0514-02598', 11, 23, NULL, 'NEW', NULL, NULL, '00:68:EB:CA:4E:16', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:03', '2026-01-22 11:29:03'),
(64, '50-ITD-0514-02575', 11, 23, NULL, 'NEW', NULL, NULL, '00:68:EB:CA:4E:61', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 11:29:03', '2026-01-22 11:29:03'),
(65, '50-ITD-0514-02558', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:50', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:00', '2026-01-22 12:40:00'),
(66, '50-ITD-0514-02565', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:60:0A:9E', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:00', '2026-01-22 12:40:00'),
(67, '50-ITD-0514-02626', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:96:FD', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:00', '2026-01-22 12:40:00'),
(68, '50-ITD-0514-02574', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:AF', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:00', '2026-01-22 12:40:00'),
(69, '50-ITD-0514-02666', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:97:5B', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(70, '50-ITD-0514-02541', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:51:2C', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(71, '50-ITD-0514-02595', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:71', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(72, '50-ITD-0514-02570', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:B4', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(73, '50-ITD-0514-02573', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4D:CA', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(74, '50-ITD-0514-02662', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:98:62', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(75, '50-ITD-0514-02556', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:32:AB', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(76, '50-ITD-0514-02546', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4D:B0', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:01', '2026-01-22 12:40:01'),
(77, '50-ITD-0514-02642', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:98:10', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:02', '2026-01-22 12:40:02'),
(78, '50-ITD-0514-02667', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:95:76', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:02', '2026-01-22 12:40:02'),
(79, '50-ITD-0514- 02552', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:3E:FE', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:02', '2026-01-22 12:40:02'),
(80, '50-ITD-0514-02543', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:A9', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:02', '2026-01-22 12:40:02'),
(81, '50-ITD-0514-02597', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4D:98', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:02', '2026-01-22 12:40:02'),
(82, '50-ITD-0514-02627', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:96:C5', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:02', '2026-01-22 12:40:02'),
(83, '50-ITD-0514-02577', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:3A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:02', '2026-01-22 12:40:02'),
(84, '50-ITD-0514-02550', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:B1', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(85, '50-ITD-0514-02559', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:40:9D', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(86, '50-ITD-0514-02665', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:94:49', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(87, '50-ITD-0514-02617', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:99:6C', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(88, '50-ITD-0514-02547', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:CA', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(89, '50-ITD-0514-02674', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:95:27', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(90, '50-ITD-0514-02582', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4D:59', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(91, '50-ITD-0514-02580', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:60:0B:FD', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:03', '2026-01-22 12:40:03'),
(92, '50-ITD-0514-02606', 11, 23, 'HP', 'NEW', NULL, NULL, '6C:02:E0:5F:99:80', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:04', '2026-01-22 12:40:04'),
(93, '50-ITD-0514-02545', 11, 23, 'HP', 'NEW', NULL, NULL, '00:68:EB:CA:4E:99', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 12:40:04', '2026-01-22 12:40:04'),
(94, '50-LAB-0514-791', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:12', '2026-01-22 13:12:12'),
(95, '50-LAB-514-190', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:12', '2026-01-22 13:12:12'),
(96, '50-LAB-514-125', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:12', '2026-01-22 13:12:12'),
(97, '50-LAB-514-83', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:12', '2026-01-22 13:12:12'),
(98, '50-LAB-514-80', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:12', '2026-01-22 13:12:12'),
(99, '50-ITD-0592-001', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:12', '2026-01-22 13:12:12'),
(100, '50-LAB-514-124', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:12', '2026-01-22 13:12:12'),
(101, '50-LAB-514-173', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:13', '2026-01-22 13:12:13'),
(102, '50-ITD-0592-00181', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:13', '2026-01-22 13:12:13'),
(103, '50-ITD-00592-00155', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:13', '2026-01-22 13:12:13'),
(104, '50-ITD-0592-00043', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:13', '2026-01-22 13:12:13'),
(105, '50-ITD-00592-00157', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:13', '2026-01-22 13:12:13'),
(106, '50-LAB-0514-1396', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:13', '2026-01-22 13:12:13'),
(107, '50-ITD-00592-00158', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(108, '50-LAB-0514-123', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(109, '50-LAB-514-109', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(110, '50-ITD-0514-02173', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(111, '50-LAB-514-77', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(112, '50-ITD-0514-1337', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(113, '50-ITD-0514-137', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(114, '50-ITD-0514-1352', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:14', '2026-01-22 13:12:14'),
(115, 'SL# 3CQ8050H6W', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:15', '2026-01-22 13:12:15'),
(116, '50-ITD-0514-1301', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:15', '2026-01-22 13:12:15'),
(117, 'SL# 3CQ80409HF', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:15', '2026-01-22 13:12:15'),
(118, 'SL# 3CQ8050HP3', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:15', '2026-01-22 13:12:15'),
(119, '50-ITD-0514-1349', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:15', '2026-01-22 13:12:15'),
(120, 'SL# 3CQ80619D1', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:15', '2026-01-22 13:12:15'),
(121, '50-ITD-0514-1321', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:15', '2026-01-22 13:12:15'),
(122, '50-LAB-514-1318', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(123, '50-ITD-0514-1297', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(124, '50-ITD-00592-00156', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(125, 'Sl# 3CQ8042NNM', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(126, '50-ITD-0514-02107', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(127, '50-ITD-0514-1289', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(128, '50-ITD-0514-00177', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(129, 'Sl# 51717069NN', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:16', '2026-01-22 13:12:16'),
(130, '50-ITD-0592-008', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:17', '2026-01-22 13:12:17'),
(131, '50-ITD-Sl# 3cQ80619B2', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:17', '2026-01-22 13:12:17'),
(132, '50-ITD-0514-1395', 12, 25, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:17', '2026-01-22 13:12:17'),
(133, '50-EML-0514-1587', 12, 26, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:17', '2026-01-22 13:12:17'),
(134, '50-ITD-0514-00174', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:17', '2026-01-22 13:12:17'),
(136, '50-ITD-0514-00176', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:17', '2026-01-22 13:12:17'),
(137, '50-ITD-00592-00169', 12, 24, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 13:12:18', '2026-01-22 13:12:18'),
(138, '50-ITD-0514-02099', 12, 23, 'N/A', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-01-22 14:00:05', '2026-01-22 14:00:05'),
(152, '50-ITD-0508-00454', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E4010054', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:04', '2026-02-03 09:39:04'),
(153, '50-ITD-0508-00548', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC253501194', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:04', '2026-02-03 09:39:04'),
(154, '50-ITD-0508-00428', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E3430045', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:04', '2026-02-03 09:39:04'),
(155, '50-ITD-0508-00491', 13, 27, 'SP7', 'NEW', NULL, NULL, 'VWJ243101469', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:04', '2026-02-03 09:39:04'),
(156, '50-ITD-0508-00536', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC250301022', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:05', '2026-02-03 09:39:05'),
(157, '50-ITD-0508-00388', 13, 28, NULL, 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:05', '2026-02-03 09:39:05'),
(158, '50-ITD-0508-00472', 13, 27, 'SP7', 'NEW', NULL, NULL, 'N/A', NULL, 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:05', '2026-02-03 09:39:05'),
(159, '50-ITD-0508-00473', 13, 27, 'SP7', 'NEW', NULL, NULL, 'N/A', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:05', '2026-02-03 09:39:05'),
(160, '50-ITD-0508-00529', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC250301387', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:06', '2026-02-03 09:39:06'),
(161, '50-ITD-0508-00532', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC250301322', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:06', '2026-02-03 09:39:06'),
(162, '50-ITD-0508-00543', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC253201215', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:06', '2026-02-03 09:39:06'),
(163, '50-ITD-0508-00497', 13, 29, NULL, 'NEW', NULL, NULL, 'Q7D6450XAAA1B0066', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:06', '2026-02-03 09:39:06'),
(164, '50-ITD-0508-00547', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC253201224', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:06', '2026-02-03 09:39:06'),
(165, '50-ITD-0508-00506', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC250301219', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:06', '2026-02-03 09:39:06'),
(166, '50-ITD-0508-00488', 13, 27, 'SP7', 'NEW', NULL, NULL, 'VWJ243101478', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:06', '2026-02-03 09:39:06'),
(167, '50-ITD-0508-00413', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E4010036', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:07', '2026-02-03 09:39:07'),
(168, '50-ITD-0508-00531', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC245101398', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:07', '2026-02-03 09:39:07'),
(169, '50-ITD-0508-00540', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC250301385', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:07', '2026-02-03 09:39:07'),
(170, '50-ITD-0508-00304', 13, 27, 'SP7', 'NEW', NULL, NULL, 'N/A', NULL, 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:07', '2026-02-03 09:39:07'),
(171, '50-ITD-0508-00471', 13, 27, 'SP7', 'NEW', NULL, NULL, 'N/A', NULL, 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:07', '2026-02-03 09:39:07'),
(172, '50-ITD-0508-00420', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E4010026', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:07', '2026-02-03 09:39:07'),
(173, '50-ITD-0508-00509', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC250301316', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:08', '2026-02-03 09:39:08'),
(174, '50-ITD-0508-00487', 13, 27, 'SP7', 'NEW', NULL, NULL, 'VWJ241501450', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:08', '2026-02-03 09:39:08'),
(175, '50-ITD-0508-00424', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E4010023', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:08', '2026-02-03 09:39:08'),
(176, '50-ITD-0508-00422', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E3430036', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:08', '2026-02-03 09:39:08'),
(177, '50-ITD-0508-00544', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC253201181', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:08', '2026-02-03 09:39:08'),
(178, '50-ITD-0508-00545', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC253501179', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:08', '2026-02-03 09:39:08'),
(179, '50-ITD-0508-00485', 13, 27, 'SP7', 'NEW', NULL, NULL, 'VWJ241501450', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:09', '2026-02-03 09:39:09'),
(180, '50-ITD-0508-00421', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E3430077', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:09', '2026-02-03 09:39:09'),
(181, '50-ITD-0508-00546', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC253501193', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:09', '2026-02-03 09:39:09'),
(182, '50-ITD-0508-00502', 13, 29, NULL, 'NEW', NULL, NULL, 'Q7D6450XAAA1B0015', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:09', '2026-02-03 09:39:09'),
(183, '50-ITD-00508-00580', 13, 27, 'SP7', 'NEW', NULL, NULL, 'XZC253501141', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:09', '2026-02-03 09:39:09'),
(184, '50-ITD-0508-429', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E4010039', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:09', '2026-02-03 09:39:09'),
(185, '50-ITD-0508-430', 13, 28, NULL, 'NEW', NULL, NULL, '33130286E4010048', '0000-00-00', 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:10', '2026-02-03 09:39:10'),
(186, '50-ITD-0508-00465', 13, 27, 'SP7', 'NEW', NULL, NULL, 'N/A', NULL, 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:10', '2026-02-03 09:39:10'),
(187, '50-ITD-0508-00466', 13, 27, 'SP7', 'NEW', NULL, NULL, 'N/A', NULL, 36, NULL, 1, 0, NULL, NULL, '2026-02-03 09:39:10', '2026-02-03 09:39:10'),
(188, 'U001', 14, 30, 'Manual', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:26', '2026-02-03 11:17:26'),
(189, 'U002', 14, 30, 'Manual', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:26', '2026-02-03 11:17:26'),
(190, '50-ITD-0510-0231', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:26', '2026-02-03 11:17:26'),
(191, 'U003', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:27', '2026-02-03 11:17:27'),
(192, '50-ITD-0510-00262', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:27', '2026-02-03 11:17:27'),
(193, 'U004', 14, 30, 'Manual', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:27', '2026-02-03 11:17:27'),
(194, 'U005', 14, 30, 'Manual', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:27', '2026-02-03 11:17:27'),
(195, '50-ITD-00510-00267', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:27', '2026-02-03 11:17:27'),
(196, 'U006', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:27', '2026-02-03 11:17:27'),
(197, '50-ITD-0510-00269', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:27', '2026-02-03 11:17:27'),
(198, 'U007', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:28', '2026-02-03 11:17:28'),
(199, 'U008', 14, 32, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:28', '2026-02-03 11:17:28'),
(200, '50-ITD-00510-00335', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:28', '2026-02-03 11:17:28'),
(201, 'U009', 14, 33, 'Manual', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:28', '2026-02-03 11:17:28'),
(202, 'U0010', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:28', '2026-02-03 11:17:28'),
(203, 'U0011', 14, 34, 'Manual', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:28', '2026-02-03 11:17:28'),
(204, '50-ITD-00510-00338', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:28', '2026-02-03 11:17:28'),
(205, '50-ITD-00510-00337', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(206, 'U12', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(207, 'U13', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(208, 'U14', 14, 31, 'MANUAL', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(209, 'U15', 14, 30, 'MANUAL', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(210, '50-ITD-00510-00336', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(211, 'U16', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(212, 'U17', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:29', '2026-02-03 11:17:29'),
(213, 'U18', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(214, 'U19', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(215, 'U20', 14, 35, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(216, 'U21', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(217, '50-ITD-00510-00339', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(218, 'U22', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(219, '50-ITD-0510-099', 14, 35, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(220, 'U23', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:30', '2026-02-03 11:17:30'),
(221, 'U24', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:31', '2026-02-03 11:17:31'),
(222, 'U25', 14, 35, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:31', '2026-02-03 11:17:31'),
(223, 'U26', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:31', '2026-02-03 11:17:31'),
(224, '50-ITD-00510-00340', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:31', '2026-02-03 11:17:31'),
(225, 'U27', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:31', '2026-02-03 11:17:31'),
(226, '50-ITD-00510-00341', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:31', '2026-02-03 11:17:31'),
(227, 'U28', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:31', '2026-02-03 11:17:31'),
(228, 'U29', 14, 30, 'Manual', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:32', '2026-02-03 11:17:32'),
(229, 'U30', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:32', '2026-02-03 11:17:32'),
(230, 'U31', 14, 35, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:32', '2026-02-03 11:17:32'),
(231, 'U32', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:17:32', '2026-02-03 11:17:32'),
(232, 'U33', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:31:00', '2026-02-03 11:31:00'),
(233, 'U34', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:31:00', '2026-02-03 11:31:00'),
(234, 'U35', 14, 31, 'Auto', 'NEW', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-02-03 11:31:01', '2026-02-03 11:31:01');

-- --------------------------------------------------------

--
-- Table structure for table `device_brands`
--

CREATE TABLE `device_brands` (
  `brand_id` int(11) NOT NULL,
  `brand_name` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `device_brands`
--

INSERT INTO `device_brands` (`brand_id`, `brand_name`, `created_at`) VALUES
(22, 'VIEWSONIC', '2026-01-15 10:50:07'),
(23, 'HP', '2026-01-22 11:29:01'),
(24, 'WALTON', '2026-01-22 13:12:13'),
(25, 'NEC', '2026-01-22 13:12:13'),
(26, 'DELL', '2026-01-22 13:12:17'),
(27, 'VIEW SONIC', '2026-01-22 14:14:14'),
(28, 'BOXLIGHT', '2026-02-03 09:39:04'),
(29, 'OPTOMA', '2026-02-03 09:39:06'),
(30, 'MEDIUM', '2026-02-03 11:17:26'),
(31, 'APOLLO', '2026-02-03 11:17:26'),
(32, 'DOPHA', '2026-02-03 11:17:28'),
(33, 'BRAUN', '2026-02-03 11:17:28'),
(34, 'FOCUS', '2026-02-03 11:17:28'),
(35, 'FLORA', '2026-02-03 11:17:30');

-- --------------------------------------------------------

--
-- Table structure for table `device_installations`
--

CREATE TABLE `device_installations` (
  `installation_id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `installed_date` date NOT NULL,
  `withdrawn_date` date DEFAULT NULL,
  `installed_by` int(11) NOT NULL,
  `team_members` text DEFAULT NULL COMMENT 'Comma-separated list of team members',
  `installation_type` enum('NEW_INSTALLATION','REPAIRED','OLD_REINSTALL') DEFAULT 'NEW_INSTALLATION' COMMENT 'Type of installation: new, repaired, or old device reinstallation',
  `installer_name` varchar(255) DEFAULT NULL COMMENT 'Manually entered installer name',
  `installer_id` varchar(100) DEFAULT NULL COMMENT 'Manually entered installer ID',
  `withdrawn_by` int(11) DEFAULT NULL,
  `withdrawer_name` varchar(255) DEFAULT NULL COMMENT 'Manually entered withdrawer name',
  `withdrawer_id` varchar(100) DEFAULT NULL COMMENT 'Manually entered withdrawer ID',
  `data_entry_by` int(11) DEFAULT NULL COMMENT 'User who entered/modified this record',
  `gate_pass_number` varchar(100) DEFAULT NULL COMMENT 'Gate pass reference number',
  `gate_pass_date` date DEFAULT NULL COMMENT 'Gate pass issue date',
  `installation_notes` text DEFAULT NULL,
  `withdrawal_notes` text DEFAULT NULL,
  `issue_at_withdrawal` varchar(255) DEFAULT NULL COMMENT 'Issue found at withdrawal',
  `storage_location` varchar(100) DEFAULT NULL COMMENT 'Where device is stored after withdrawal',
  `status` enum('active','withdrawn') DEFAULT 'active',
  `is_deleted` tinyint(1) DEFAULT 0,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `device_installations`
--

INSERT INTO `device_installations` (`installation_id`, `device_id`, `room_id`, `installed_date`, `withdrawn_date`, `installed_by`, `team_members`, `installation_type`, `installer_name`, `installer_id`, `withdrawn_by`, `withdrawer_name`, `withdrawer_id`, `data_entry_by`, `gate_pass_number`, `gate_pass_date`, `installation_notes`, `withdrawal_notes`, `issue_at_withdrawal`, `storage_location`, `status`, `is_deleted`, `deleted_at`, `deleted_by`, `created_at`, `updated_at`) VALUES
(5, 50, 50, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:38', '2026-01-22 11:58:38'),
(6, 51, 14, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:38', '2026-01-22 11:58:38'),
(7, 52, 51, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:39', '2026-01-22 11:58:39'),
(8, 53, 52, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:39', '2026-01-22 11:58:39'),
(9, 54, 53, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:39', '2026-01-22 11:58:39'),
(10, 55, 15, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:39', '2026-01-22 11:58:39'),
(11, 56, 16, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:39', '2026-01-22 11:58:39'),
(12, 57, 54, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:40', '2026-01-22 11:58:40'),
(13, 58, 17, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:40', '2026-01-22 11:58:40'),
(14, 59, 55, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:40', '2026-01-22 11:58:40'),
(15, 60, 56, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:58:40', '2026-01-22 11:58:40'),
(16, 61, 18, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:59:23', '2026-01-22 11:59:23'),
(17, 62, 19, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:59:23', '2026-01-22 11:59:23'),
(18, 63, 57, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:59:23', '2026-01-22 11:59:23'),
(19, 64, 58, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 11:59:23', '2026-01-22 11:59:23'),
(20, 65, 59, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:07', '2026-01-22 12:55:07'),
(21, 66, 60, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:07', '2026-01-22 12:55:07'),
(22, 67, 61, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:07', '2026-01-22 12:55:07'),
(23, 68, 62, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:07', '2026-01-22 12:55:07'),
(24, 69, 63, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:07', '2026-01-22 12:55:07'),
(25, 70, 64, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:08', '2026-01-22 12:55:08'),
(26, 71, 20, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:08', '2026-01-22 12:55:08'),
(27, 72, 65, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:08', '2026-01-22 12:55:08'),
(28, 73, 66, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:08', '2026-01-22 12:55:08'),
(29, 74, 21, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:08', '2026-01-22 12:55:08'),
(30, 75, 67, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:08', '2026-01-22 12:55:08'),
(31, 76, 68, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:09', '2026-01-22 12:55:09'),
(32, 77, 69, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:09', '2026-01-22 12:55:09'),
(33, 78, 70, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:09', '2026-01-22 12:55:09'),
(34, 79, 71, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:09', '2026-01-22 12:55:09'),
(35, 80, 22, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:09', '2026-01-22 12:55:09'),
(36, 81, 72, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:09', '2026-01-22 12:55:09'),
(37, 82, 73, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:10', '2026-01-22 12:55:10'),
(38, 83, 74, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:10', '2026-01-22 12:55:10'),
(39, 84, 75, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:10', '2026-01-22 12:55:10'),
(40, 85, 76, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:10', '2026-01-22 12:55:10'),
(41, 86, 77, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:10', '2026-01-22 12:55:10'),
(42, 87, 23, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:10', '2026-01-22 12:55:10'),
(43, 88, 78, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:11', '2026-01-22 12:55:11'),
(44, 89, 79, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:11', '2026-01-22 12:55:11'),
(45, 90, 24, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:11', '2026-01-22 12:55:11'),
(46, 91, 80, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:11', '2026-01-22 12:55:11'),
(47, 92, 81, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:11', '2026-01-22 12:55:11'),
(48, 93, 82, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 12:55:11', '2026-01-22 12:55:11'),
(49, 94, 50, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:33', '2026-01-22 13:50:33'),
(50, 95, 14, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:34', '2026-01-22 13:50:34'),
(51, 96, 51, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:34', '2026-01-22 13:50:34'),
(52, 97, 52, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:34', '2026-01-22 13:50:34'),
(53, 98, 53, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:34', '2026-01-22 13:50:34'),
(54, 99, 15, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:34', '2026-01-22 13:50:34'),
(55, 100, 16, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:35', '2026-01-22 13:50:35'),
(56, 101, 54, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:35', '2026-01-22 13:50:35'),
(57, 102, 17, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:35', '2026-01-22 13:50:35'),
(58, 103, 55, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:35', '2026-01-22 13:50:35'),
(59, 104, 56, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:35', '2026-01-22 13:50:35'),
(60, 105, 18, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:35', '2026-01-22 13:50:35'),
(61, 106, 19, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:36', '2026-01-22 13:50:36'),
(62, 107, 57, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:36', '2026-01-22 13:50:36'),
(63, 108, 58, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:36', '2026-01-22 13:50:36'),
(64, 109, 59, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:36', '2026-01-22 13:50:36'),
(65, 110, 60, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:36', '2026-01-22 13:50:36'),
(66, 111, 61, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:36', '2026-01-22 13:50:36'),
(67, 112, 62, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:37', '2026-01-22 13:50:37'),
(68, 113, 63, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:37', '2026-01-22 13:50:37'),
(69, 114, 64, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:37', '2026-01-22 13:50:37'),
(70, 115, 20, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:37', '2026-01-22 13:50:37'),
(71, 116, 65, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:37', '2026-01-22 13:50:37'),
(72, 117, 66, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:38', '2026-01-22 13:50:38'),
(73, 118, 21, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:38', '2026-01-22 13:50:38'),
(74, 119, 67, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:38', '2026-01-22 13:50:38'),
(75, 120, 68, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:38', '2026-01-22 13:50:38'),
(76, 121, 69, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:38', '2026-01-22 13:50:38'),
(77, 122, 70, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:38', '2026-01-22 13:50:38'),
(78, 123, 71, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:39', '2026-01-22 13:50:39'),
(79, 124, 22, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:39', '2026-01-22 13:50:39'),
(80, 125, 72, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:39', '2026-01-22 13:50:39'),
(81, 126, 73, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:39', '2026-01-22 13:50:39'),
(82, 127, 74, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:39', '2026-01-22 13:50:39'),
(83, 128, 75, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:40', '2026-01-22 13:50:40'),
(84, 129, 76, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:40', '2026-01-22 13:50:40'),
(85, 130, 77, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:40', '2026-01-22 13:50:40'),
(86, 131, 23, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:40', '2026-01-22 13:50:40'),
(87, 132, 78, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:40', '2026-01-22 13:50:40'),
(88, 133, 79, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:40', '2026-01-22 13:50:40'),
(89, 134, 24, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:41', '2026-01-22 13:50:41'),
(90, 136, 81, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:41', '2026-01-22 13:50:41'),
(91, 137, 82, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-22 13:50:41', '2026-01-22 13:50:41'),
(92, 138, 80, '2022-02-27', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, '', NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-01-27 13:54:12', '2026-01-27 13:54:12'),
(93, 152, 50, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:49', '2026-02-03 09:45:49'),
(94, 18, 14, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:49', '2026-02-03 09:45:49'),
(95, 153, 51, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:49', '2026-02-03 09:45:49'),
(96, 154, 52, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:50', '2026-02-03 09:45:50'),
(97, 155, 53, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:50', '2026-02-03 09:45:50'),
(98, 19, 15, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:50', '2026-02-03 09:45:50'),
(99, 20, 16, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:50', '2026-02-03 09:45:50'),
(100, 156, 54, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:50', '2026-02-03 09:45:50'),
(101, 21, 17, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:50', '2026-02-03 09:45:50'),
(102, 157, 55, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:51', '2026-02-03 09:45:51'),
(103, 158, 56, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:51', '2026-02-03 09:45:51'),
(104, 159, 56, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:51', '2026-02-03 09:45:51'),
(105, 22, 18, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:51', '2026-02-03 09:45:51'),
(106, 23, 19, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:51', '2026-02-03 09:45:51'),
(107, 160, 57, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:52', '2026-02-03 09:45:52'),
(108, 161, 58, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:52', '2026-02-03 09:45:52'),
(109, 162, 59, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:52', '2026-02-03 09:45:52'),
(110, 163, 60, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:52', '2026-02-03 09:45:52'),
(111, 164, 61, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:52', '2026-02-03 09:45:52'),
(112, 165, 62, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:53', '2026-02-03 09:45:53'),
(113, 166, 63, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:53', '2026-02-03 09:45:53'),
(114, 167, 64, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:53', '2026-02-03 09:45:53'),
(115, 24, 20, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:53', '2026-02-03 09:45:53'),
(116, 168, 65, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:53', '2026-02-03 09:45:53'),
(117, 169, 66, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:53', '2026-02-03 09:45:53'),
(118, 25, 21, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:54', '2026-02-03 09:45:54'),
(119, 170, 67, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:54', '2026-02-03 09:45:54'),
(120, 171, 67, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:54', '2026-02-03 09:45:54'),
(121, 172, 68, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:54', '2026-02-03 09:45:54'),
(122, 173, 69, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:54', '2026-02-03 09:45:54'),
(123, 174, 70, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:55', '2026-02-03 09:45:55'),
(124, 175, 71, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:55', '2026-02-03 09:45:55'),
(125, 26, 22, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:55', '2026-02-03 09:45:55'),
(126, 176, 72, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:55', '2026-02-03 09:45:55'),
(127, 177, 73, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:55', '2026-02-03 09:45:55'),
(128, 178, 74, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:56', '2026-02-03 09:45:56'),
(129, 179, 75, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:56', '2026-02-03 09:45:56'),
(130, 180, 76, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:56', '2026-02-03 09:45:56'),
(131, 181, 77, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:56', '2026-02-03 09:45:56'),
(132, 27, 23, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:56', '2026-02-03 09:45:56'),
(133, 182, 78, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:56', '2026-02-03 09:45:56'),
(134, 183, 79, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:57', '2026-02-03 09:45:57'),
(135, 28, 24, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:57', '2026-02-03 09:45:57'),
(136, 184, 80, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:57', '2026-02-03 09:45:57'),
(137, 185, 81, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:57', '2026-02-03 09:45:57'),
(138, 186, 82, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:57', '2026-02-03 09:45:57'),
(139, 187, 82, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 09:45:58', '2026-02-03 09:45:58'),
(140, 188, 50, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:33', '2026-02-03 11:34:33'),
(141, 189, 14, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:33', '2026-02-03 11:34:33'),
(142, 190, 51, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:33', '2026-02-03 11:34:33'),
(143, 191, 52, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:33', '2026-02-03 11:34:33'),
(144, 192, 53, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:34', '2026-02-03 11:34:34'),
(145, 193, 15, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:34', '2026-02-03 11:34:34'),
(146, 194, 16, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:34', '2026-02-03 11:34:34'),
(147, 195, 54, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:34', '2026-02-03 11:34:34'),
(148, 196, 17, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:34', '2026-02-03 11:34:34'),
(149, 197, 55, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:34', '2026-02-03 11:34:34'),
(150, 198, 56, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:35', '2026-02-03 11:34:35'),
(151, 199, 56, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:35', '2026-02-03 11:34:35'),
(152, 200, 18, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:35', '2026-02-03 11:34:35'),
(153, 201, 19, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:35', '2026-02-03 11:34:35'),
(154, 202, 57, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:35', '2026-02-03 11:34:35'),
(155, 203, 58, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:36', '2026-02-03 11:34:36'),
(156, 204, 59, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:36', '2026-02-03 11:34:36'),
(157, 205, 60, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:36', '2026-02-03 11:34:36'),
(158, 206, 61, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:36', '2026-02-03 11:34:36'),
(159, 207, 62, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:36', '2026-02-03 11:34:36'),
(160, 208, 63, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:37', '2026-02-03 11:34:37'),
(161, 209, 64, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:37', '2026-02-03 11:34:37'),
(162, 210, 20, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:37', '2026-02-03 11:34:37'),
(163, 211, 65, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:37', '2026-02-03 11:34:37'),
(164, 212, 66, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:37', '2026-02-03 11:34:37'),
(165, 213, 21, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:37', '2026-02-03 11:34:37'),
(166, 214, 67, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:38', '2026-02-03 11:34:38'),
(167, 215, 67, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:38', '2026-02-03 11:34:38'),
(168, 216, 68, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:38', '2026-02-03 11:34:38'),
(169, 217, 69, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:38', '2026-02-03 11:34:38'),
(170, 218, 70, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:38', '2026-02-03 11:34:38'),
(171, 219, 71, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:39', '2026-02-03 11:34:39'),
(172, 220, 22, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:39', '2026-02-03 11:34:39'),
(173, 221, 72, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:39', '2026-02-03 11:34:39'),
(174, 222, 73, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:39', '2026-02-03 11:34:39'),
(175, 223, 74, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:39', '2026-02-03 11:34:39'),
(176, 224, 75, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:40', '2026-02-03 11:34:40'),
(177, 225, 76, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:40', '2026-02-03 11:34:40'),
(178, 226, 77, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:40', '2026-02-03 11:34:40'),
(179, 227, 23, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:40', '2026-02-03 11:34:40'),
(180, 228, 78, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:40', '2026-02-03 11:34:40'),
(181, 229, 79, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:41', '2026-02-03 11:34:41'),
(182, 230, 24, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:41', '2026-02-03 11:34:41'),
(183, 231, 80, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:41', '2026-02-03 11:34:41'),
(184, 232, 81, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:41', '2026-02-03 11:34:41'),
(185, 233, 82, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:41', '2026-02-03 11:34:41'),
(186, 234, 82, '0000-00-00', NULL, 1, NULL, 'NEW_INSTALLATION', NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 'active', 0, NULL, NULL, '2026-02-03 11:34:41', '2026-02-03 11:34:41');

-- --------------------------------------------------------

--
-- Table structure for table `device_issues`
--

CREATE TABLE `device_issues` (
  `issue_id` int(11) NOT NULL,
  `issue_name` varchar(100) NOT NULL,
  `issue_category` enum('Hardware','Display','Power','Other') DEFAULT 'Other',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `device_issues`
--

INSERT INTO `device_issues` (`issue_id`, `issue_name`, `issue_category`, `is_active`, `created_at`) VALUES
(1, 'Lamp Damage', 'Hardware', 1, '2025-12-14 03:03:43'),
(2, 'Red Light Issue', 'Power', 1, '2025-12-14 03:03:43'),
(3, 'Poor Focus', 'Display', 1, '2025-12-14 03:03:43'),
(4, 'Lamp Issue', 'Hardware', 1, '2025-12-14 03:03:43'),
(5, 'Off Properly', 'Other', 1, '2025-12-14 03:03:43'),
(6, 'Lamp fuse', 'Hardware', 1, '2025-12-14 03:03:43'),
(7, 'No Focus', 'Display', 1, '2025-12-14 03:03:43');

-- --------------------------------------------------------

--
-- Table structure for table `device_types`
--

CREATE TABLE `device_types` (
  `type_id` int(11) NOT NULL,
  `type_name` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `device_types`
--

INSERT INTO `device_types` (`type_id`, `type_name`, `description`, `created_at`) VALUES
(10, 'Multimedia Projector', 'Auto-created from CSV import', '2026-01-15 10:50:07'),
(11, 'PC', 'Auto-created from CSV import', '2026-01-22 11:29:01'),
(12, 'Monitor', 'Auto-created from CSV import', '2026-01-22 13:12:12'),
(13, 'Multimedia', 'Auto-created from CSV import', '2026-01-22 14:14:14'),
(14, 'Multimedia Screen', 'Auto-created from CSV import', '2026-02-03 11:17:26');

-- --------------------------------------------------------

--
-- Table structure for table `gate_passes`
--

CREATE TABLE `gate_passes` (
  `gate_pass_id` int(11) NOT NULL,
  `gate_pass_number` varchar(50) NOT NULL,
  `gate_pass_date` date NOT NULL,
  `pass_direction` enum('incoming','outgoing') NOT NULL DEFAULT 'outgoing',
  `gate_pass_time` time DEFAULT NULL,
  `department` varchar(255) DEFAULT NULL,
  `gate_name` varchar(255) DEFAULT NULL,
  `vendor_destination` varchar(255) DEFAULT NULL,
  `bearer_name` varchar(150) DEFAULT NULL,
  `bearer_company` varchar(150) DEFAULT NULL,
  `bearer_contact_no` varchar(50) DEFAULT NULL,
  `bearer_signature` varchar(255) DEFAULT NULL,
  `bearer_signature_date` date DEFAULT NULL,
  `security_officer_name` varchar(150) DEFAULT NULL,
  `security_officer_designation` varchar(150) DEFAULT NULL,
  `security_officer_ext` varchar(50) DEFAULT NULL,
  `security_officer_signature` varchar(255) DEFAULT NULL,
  `security_officer_signature_date` date DEFAULT NULL,
  `processing_name` varchar(150) DEFAULT NULL,
  `processing_designation` varchar(150) DEFAULT NULL,
  `processing_ext` varchar(50) DEFAULT NULL,
  `processing_signature` varchar(255) DEFAULT NULL,
  `processing_signature_date` date DEFAULT NULL,
  `authorized_name` varchar(150) DEFAULT NULL,
  `authorized_designation` varchar(150) DEFAULT NULL,
  `authorized_ext` varchar(50) DEFAULT NULL,
  `authorized_signature` varchar(255) DEFAULT NULL,
  `authorized_signature_date` date DEFAULT NULL,
  `consignee_name` text DEFAULT NULL,
  `destination` varchar(255) DEFAULT NULL,
  `destination_room_id` int(11) DEFAULT NULL,
  `carrier_name` varchar(100) NOT NULL,
  `carrier_appointment` varchar(100) DEFAULT NULL,
  `carrier_department` varchar(100) DEFAULT NULL,
  `carrier_telephone` varchar(50) DEFAULT NULL,
  `security_name` varchar(100) DEFAULT NULL,
  `security_appointment` varchar(100) DEFAULT NULL,
  `security_department` varchar(100) DEFAULT NULL,
  `security_telephone` varchar(50) DEFAULT NULL,
  `receiver_name` varchar(100) DEFAULT NULL,
  `receiver_appointment` varchar(100) DEFAULT NULL,
  `receiver_department` varchar(100) DEFAULT NULL,
  `receiver_telephone` varchar(50) DEFAULT NULL,
  `purpose` varchar(100) NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('active','completed','cancelled') DEFAULT 'active',
  `created_by` int(11) NOT NULL,
  `is_deleted` tinyint(1) DEFAULT 0,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gate_pass_devices`
--

CREATE TABLE `gate_pass_devices` (
  `gate_pass_device_id` int(11) NOT NULL,
  `gate_pass_id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `room_id` int(11) NOT NULL,
  `room_number` varchar(50) NOT NULL,
  `room_name` varchar(100) DEFAULT NULL,
  `building` varchar(100) DEFAULT NULL,
  `floor` int(11) DEFAULT NULL,
  `capacity` int(11) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rooms`
--

INSERT INTO `rooms` (`room_id`, `room_number`, `room_name`, `building`, `floor`, `capacity`, `is_active`, `created_at`, `updated_at`) VALUES
(14, 'NAC 202', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:58', '2026-01-15 10:40:58'),
(15, 'NAC 206', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:58', '2026-01-15 10:40:58'),
(16, 'NAC 207', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:58', '2026-01-15 10:40:58'),
(17, 'NAC 209', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:58', '2026-01-15 10:40:58'),
(18, 'NAC 213', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:58', '2026-01-15 10:40:58'),
(19, 'NAC 214', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:58', '2026-01-15 10:40:58'),
(20, 'NAC 307', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:58', '2026-01-15 10:40:58'),
(21, 'NAC 310', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:59', '2026-01-15 10:40:59'),
(22, 'NAC 402', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:59', '2026-01-15 10:40:59'),
(23, 'NAC 409', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:59', '2026-01-15 10:40:59'),
(24, 'NAC 412', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:59', '2026-01-15 10:40:59'),
(25, 'NAC 501', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:59', '2026-01-15 10:40:59'),
(26, 'NAC 506', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:40:59', '2026-01-15 10:40:59'),
(27, 'NAC 511', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-15 10:41:00'),
(28, 'LIB 602', 'LAB', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-22 10:45:06'),
(29, 'LIB 603', 'LAB', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-22 10:45:34'),
(30, 'LIB 605', 'LAB', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-22 10:45:58'),
(31, 'LIB 609', 'LAB', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-22 10:46:10'),
(32, 'SAC 514', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-15 10:41:00'),
(33, 'NAC 514', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-15 10:41:00'),
(34, 'NAC 618', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:01', '2026-01-15 10:41:01'),
(35, 'NAC 619', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:01', '2026-01-15 10:41:01'),
(36, 'NAC 990', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:01', '2026-01-15 10:41:01'),
(37, 'NAC 991', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:01', '2026-01-15 10:41:01'),
(38, 'NAC 1077', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:01', '2026-01-15 10:41:01'),
(39, 'SAC 303', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:01', '2026-01-15 10:41:01'),
(40, 'SAC 511', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:02', '2026-01-15 10:41:02'),
(41, 'NTR 2ND FLOOR', 'LAB Room', NULL, NULL, NULL, 1, '2026-01-15 10:41:02', '2026-01-15 10:41:02'),
(42, 'SAC 401', 'LAB Room', NULL, NULL, NULL, 1, '2026-01-15 10:41:02', '2026-01-15 10:41:02'),
(43, 'NAC501', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 10:59:33', '2026-01-20 10:59:33'),
(44, 'NAC502', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 10:59:33', '2026-01-20 10:59:33'),
(45, 'NAC503', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 10:59:33', '2026-01-20 10:59:33'),
(46, 'NAC504', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 10:59:33', '2026-01-20 10:59:33'),
(47, 'NAC505', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 10:59:33', '2026-01-20 10:59:33'),
(48, 'NAC506', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 10:59:33', '2026-01-20 10:59:33'),
(49, 'NAC507', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 10:59:34', '2026-01-20 10:59:34'),
(50, 'NAC 201', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:02', '2026-01-20 11:21:02'),
(51, 'NAC 203', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:02', '2026-01-20 11:21:02'),
(52, 'NAC 204', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:03', '2026-01-20 11:21:03'),
(53, 'NAC 205', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:03', '2026-01-20 11:21:03'),
(54, 'NAC 208', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:03', '2026-01-20 11:21:03'),
(55, 'NAC 210', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:03', '2026-01-20 11:21:03'),
(56, 'NAC 211', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:03', '2026-01-20 11:21:03'),
(57, 'NAC 215', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:04', '2026-01-20 11:21:04'),
(58, 'NAC 216', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:04', '2026-01-20 11:21:04'),
(59, 'NAC 301', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:04', '2026-01-20 11:21:04'),
(60, 'NAC 302', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:04', '2026-01-20 11:21:04'),
(61, 'NAC 303', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:04', '2026-01-20 11:21:04'),
(62, 'NAC 304', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:05', '2026-01-20 11:21:05'),
(63, 'NAC 305', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:05', '2026-01-20 11:21:05'),
(64, 'NAC 306', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:05', '2026-01-20 11:21:05'),
(65, 'NAC 308', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:05', '2026-01-20 11:21:05'),
(66, 'NAC 309', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:05', '2026-01-20 11:21:05'),
(67, 'NAC 311', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:06', '2026-01-20 11:21:06'),
(68, 'NAC 313', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:06', '2026-01-20 11:21:06'),
(69, 'NAC 314', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:06', '2026-01-20 11:21:06'),
(70, 'NAC 315', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:06', '2026-01-20 11:21:06'),
(71, 'NAC 401', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:06', '2026-01-20 11:21:06'),
(72, 'NAC 403', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:06', '2026-01-20 11:21:06'),
(73, 'NAC 404', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:06', '2026-01-20 11:21:06'),
(74, 'NAC 405', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:07', '2026-01-20 11:21:07'),
(75, 'NAC 406', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:07', '2026-01-20 11:21:07'),
(76, 'NAC 407', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:07', '2026-01-20 11:21:07'),
(77, 'NAC 408', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:07', '2026-01-20 11:21:07'),
(78, 'NAC 410', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:07', '2026-01-20 11:21:07'),
(79, 'NAC 411', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:07', '2026-01-20 11:21:07'),
(80, 'NAC 413', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:08', '2026-01-20 11:21:08'),
(81, 'NAC 414', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:08', '2026-01-20 11:21:08'),
(82, 'NAC 415', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:08', '2026-01-20 11:21:08'),
(83, 'NAC 502', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:08', '2026-01-20 11:21:08'),
(84, 'NAC 503', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:08', '2026-01-20 11:21:08'),
(85, 'NAC 504', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:08', '2026-01-20 11:21:08'),
(86, 'NAC 505', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:09', '2026-01-20 11:21:09'),
(87, 'NAC 507', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:09', '2026-01-20 11:21:09'),
(88, 'NAC 508', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:09', '2026-01-20 11:21:09'),
(89, 'NAC 509', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:09', '2026-01-20 11:21:09'),
(90, 'NAC 510', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:09', '2026-01-20 11:21:09'),
(91, 'NAC 512', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:10', '2026-01-20 11:21:10'),
(92, 'NAC 512/A', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:10', '2026-01-20 11:21:10'),
(93, 'NAC 513', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:10', '2026-01-20 11:21:10'),
(94, 'NAC 515', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:10', '2026-01-20 11:21:10'),
(95, 'NAC 517', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:10', '2026-01-20 11:21:10'),
(96, 'NAC 601', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:10', '2026-01-20 11:21:10'),
(97, 'NAC 602', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:10', '2026-01-20 11:21:10'),
(98, 'NAC 603', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:11', '2026-01-20 11:21:11'),
(99, 'NAC 604', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:11', '2026-01-20 11:21:11'),
(100, 'NAC 605', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:11', '2026-01-20 11:21:11'),
(101, 'NAC 617', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:11', '2026-01-20 11:21:11'),
(102, 'NAC 619/A', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:11', '2026-01-20 11:21:11'),
(103, 'NAC 620', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:12', '2026-01-20 11:21:12'),
(104, 'NAC 621', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:12', '2026-01-20 11:21:12'),
(105, 'NAC 992', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:12', '2026-01-20 11:21:12'),
(106, 'NAC 993', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:12', '2026-01-20 11:21:12'),
(107, 'NAC 1078', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:12', '2026-01-20 11:21:12'),
(108, 'NAC 1079', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:13', '2026-01-20 11:21:13'),
(109, 'NAC 1080', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:13', '2026-01-20 11:21:13'),
(110, 'SAC 201', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:13', '2026-01-20 11:21:13'),
(111, 'SAC 202', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:13', '2026-01-20 11:21:13'),
(112, 'SAC 203', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:13', '2026-01-20 11:21:13'),
(113, 'SAC 204', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:13', '2026-01-20 11:21:13'),
(114, 'SAC 205', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:13', '2026-01-20 11:21:13'),
(115, 'SAC 206', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:14', '2026-01-20 11:21:14'),
(116, 'SAC 207', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:14', '2026-01-20 11:21:14'),
(117, 'SAC 208', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:14', '2026-01-20 11:21:14'),
(118, 'SAC 209', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:14', '2026-01-20 11:21:14'),
(119, 'SAC 210', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:14', '2026-01-20 11:21:14'),
(120, 'SAC 211', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:14', '2026-01-20 11:21:14'),
(121, 'SAC 212', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:14', '2026-01-20 11:21:14'),
(122, 'SAC 213', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:15', '2026-01-20 11:21:15'),
(123, 'SAC 214', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:15', '2026-01-20 11:21:15'),
(124, 'SAC 215', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:15', '2026-01-20 11:21:15'),
(125, 'SAC 301', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:15', '2026-01-20 11:21:15'),
(126, 'SAC 302', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:15', '2026-01-20 11:21:15'),
(127, 'SAC 304', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:15', '2026-01-20 11:21:15'),
(128, 'SAC 305', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:15', '2026-01-20 11:21:15'),
(129, 'SAC 306', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(130, 'SAC 307', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(131, 'SAC 308', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(132, 'SAC 309', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(133, 'SAC 310', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(134, 'SAC 311', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(135, 'SAC 312', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(136, 'SAC 313', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:16', '2026-01-20 11:21:16'),
(137, 'SAC 314', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:17', '2026-01-20 11:21:17'),
(138, 'SAC 315', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:17', '2026-01-20 11:21:17'),
(139, 'SAC 316', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:17', '2026-01-20 11:21:17'),
(140, 'SAC 402', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:17', '2026-01-20 11:21:17'),
(141, 'SAC 403', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:17', '2026-01-20 11:21:17'),
(142, 'SAC 404', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:17', '2026-01-20 11:21:17'),
(143, 'SAC 405', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:18', '2026-01-20 11:21:18'),
(144, 'SAC 406', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:18', '2026-01-20 11:21:18'),
(145, 'SAC 407', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:18', '2026-01-20 11:21:18'),
(146, 'SAC 513', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:18', '2026-01-20 11:21:18'),
(147, 'OAT 601', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:18', '2026-01-20 11:21:18'),
(148, 'OAT 602', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:18', '2026-01-20 11:21:18'),
(149, 'SAC 604', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:18', '2026-01-20 11:21:18'),
(150, 'SAC 801/A', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(151, 'SAC 802', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(152, 'SAC 968', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(153, 'SAC 969', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(154, 'SAC 970', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(155, 'SAC 971', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(156, 'NTR 301', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(157, 'NTR 302', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:19', '2026-01-20 11:21:19'),
(158, 'NTR 303', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:20', '2026-01-20 11:21:20'),
(159, 'NTR 304', 'Classroom', NULL, NULL, NULL, 1, '2026-01-20 11:21:20', '2026-01-20 11:21:20');

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `session_id` varchar(128) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `last_activity` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `storage_locations`
--

CREATE TABLE `storage_locations` (
  `location_id` int(11) NOT NULL,
  `location_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `storage_locations`
--

INSERT INTO `storage_locations` (`location_id`, `location_name`, `description`, `is_active`, `created_at`) VALUES
(1, 'Basement', NULL, 1, '2025-12-14 03:03:43'),
(2, 'IT', NULL, 1, '2025-12-14 03:03:43'),
(3, 'WARREN Memo', NULL, 1, '2025-12-14 03:03:43'),
(4, 'IT Store', NULL, 1, '2025-12-14 03:03:43'),
(5, 'IT Memo', NULL, 1, '2025-12-14 03:03:43');

-- --------------------------------------------------------

--
-- Table structure for table `support_team_members`
--

CREATE TABLE `support_team_members` (
  `member_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL COMMENT 'Link to users table if member has login',
  `member_name` varchar(100) NOT NULL,
  `member_email` varchar(100) DEFAULT NULL,
  `member_phone` varchar(20) DEFAULT NULL,
  `department` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Support team members who provide classroom assistance';

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `role` enum('admin','staff','viewer') DEFAULT 'viewer' COMMENT 'admin: full access, staff: can add/edit data, viewer: read-only access',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User accounts with role-based access control';

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password_hash`, `full_name`, `email`, `role`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'admin', '$2y$12$LBWhJsqBDCbH0AG0uX1Iy.RHyfCyPL5cOP0ZfG73o/sFVnE.2/gIa', 'System Administrator', 'admin@classroom.local', 'admin', 1, '2025-11-28 16:02:13', '2025-11-28 16:13:41'),
(2, 'viewer', '$2y$10$Lb3toUxNB.ZESKb1KNmb1u47BuA080Wh/KfN/fjR9ob9fq/OQpxry', 'Guest Viewer', 'viewer@classroom.local', 'viewer', 1, '2025-11-28 16:02:13', '2026-01-14 02:35:22'),
(3, 'staff1', '$2y$10$218awptu3MLjPBoZ5UnEn.qhCrzyd3wURnO2tR1LF9HuInmXgx5X6', 'Staff User', 'staff@test.com', 'staff', 1, '2026-01-14 02:34:00', '2026-01-14 02:34:00');

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_current_device_locations`
-- (See below for the actual view)
--
CREATE TABLE `view_current_device_locations` (
`device_id` int(11)
,`device_unique_id` varchar(100)
,`type_name` varchar(50)
,`brand_name` varchar(50)
,`model` varchar(100)
,`room_number` varchar(50)
,`room_name` varchar(100)
,`installed_date` date
,`days_in_current_room` int(7)
,`installed_by_name` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_daily_support_summary`
-- (See below for the actual view)
--
CREATE TABLE `view_daily_support_summary` (
`support_date` date
,`total_supports` bigint(21)
,`team_members_active` bigint(21)
,`locations_served` bigint(21)
,`total_minutes` decimal(32,0)
,`technical_issues` bigint(21)
,`setup_issues` bigint(21)
,`training_issues` bigint(21)
,`maintenance_issues` bigint(21)
,`high_priority` bigint(21)
,`medium_priority` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_device_lifetime_stats`
-- (See below for the actual view)
--
CREATE TABLE `view_device_lifetime_stats` (
`device_id` int(11)
,`device_unique_id` varchar(100)
,`type_name` varchar(50)
,`brand_name` varchar(50)
,`model` varchar(100)
,`first_installation_date` date
,`total_lifetime_days` int(7)
,`total_installations` bigint(21)
,`total_rooms_used` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_excel_active_installations`
-- (See below for the actual view)
--
CREATE TABLE `view_excel_active_installations` (
`ID` varchar(50)
,`Location` varchar(100)
,`Multimedia Brand` varchar(50)
,`Status` enum('NEW','REPAIR','USED','WITHDRAWN')
,`NSU ID` varchar(100)
,`Manufacture SL` varchar(100)
,`Install Date` date
,`Installation Type` enum('NEW_INSTALLATION','REPAIRED','OLD_REINSTALL')
,`TEAM` text
,`Current Issue` varchar(255)
,`Storage` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_excel_withdrawn_devices`
-- (See below for the actual view)
--
CREATE TABLE `view_excel_withdrawn_devices` (
`NSU ID` varchar(100)
,`Status/Brand` varchar(50)
,`Manufacture SL` varchar(100)
,`Issue` varchar(255)
,`Store` varchar(100)
,`Withdrawn Date` date
,`Withdrawal Issue` varchar(255)
,`Notes` text
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_support_statistics`
-- (See below for the actual view)
--
CREATE TABLE `view_support_statistics` (
`member_id` int(11)
,`member_name` varchar(100)
,`department` varchar(100)
,`total_supports` bigint(21)
,`supports_last_30_days` bigint(21)
,`supports_last_7_days` bigint(21)
,`total_minutes` decimal(32,0)
,`avg_duration_minutes` decimal(14,4)
,`last_support_date` date
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_device_installation_history`
-- (See below for the actual view)
--
CREATE TABLE `v_device_installation_history` (
`installation_id` int(11)
,`device_id` int(11)
,`device_unique_id` varchar(100)
,`type_name` varchar(50)
,`brand_name` varchar(50)
,`model` varchar(100)
,`room_id` int(11)
,`room_number` varchar(50)
,`room_name` varchar(100)
,`building` varchar(100)
,`floor` int(11)
,`installed_date` date
,`withdrawn_date` date
,`status` enum('active','withdrawn')
,`installation_notes` text
,`withdrawal_notes` text
,`gate_pass_number` varchar(100)
,`gate_pass_date` date
,`days_in_room` int(7)
,`installed_by_name` varchar(255)
,`installed_by_id` varchar(100)
,`withdrawn_by_name` varchar(255)
,`withdrawn_by_id` varchar(100)
,`data_entry_by_name` varchar(100)
,`data_entry_username` varchar(50)
,`created_at` timestamp
,`updated_at` timestamp
);

-- --------------------------------------------------------

--
-- Structure for view `view_current_device_locations`
--
DROP TABLE IF EXISTS `view_current_device_locations`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_current_device_locations`  AS SELECT `d`.`device_id` AS `device_id`, `d`.`device_unique_id` AS `device_unique_id`, `dt`.`type_name` AS `type_name`, `db`.`brand_name` AS `brand_name`, `d`.`model` AS `model`, `r`.`room_number` AS `room_number`, `r`.`room_name` AS `room_name`, `di`.`installed_date` AS `installed_date`, to_days(curdate()) - to_days(`di`.`installed_date`) AS `days_in_current_room`, `u`.`full_name` AS `installed_by_name` FROM (((((`devices` `d` left join `device_types` `dt` on(`d`.`type_id` = `dt`.`type_id`)) left join `device_brands` `db` on(`d`.`brand_id` = `db`.`brand_id`)) left join `device_installations` `di` on(`d`.`device_id` = `di`.`device_id` and `di`.`status` = 'active' and `di`.`is_deleted` = 0)) left join `rooms` `r` on(`di`.`room_id` = `r`.`room_id`)) left join `users` `u` on(`di`.`installed_by` = `u`.`user_id`)) WHERE `d`.`is_deleted` = 0 ;

-- --------------------------------------------------------

--
-- Structure for view `view_daily_support_summary`
--
DROP TABLE IF EXISTS `view_daily_support_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_daily_support_summary`  AS SELECT `csr`.`support_date` AS `support_date`, count(`csr`.`support_id`) AS `total_supports`, count(distinct `csr`.`member_id`) AS `team_members_active`, count(distinct `csr`.`location`) AS `locations_served`, sum(case when `csr`.`duration_minutes` is not null then `csr`.`duration_minutes` else 0 end) AS `total_minutes`, count(case when `csr`.`issue_type` = 'TECHNICAL' then 1 end) AS `technical_issues`, count(case when `csr`.`issue_type` = 'SETUP' then 1 end) AS `setup_issues`, count(case when `csr`.`issue_type` = 'TRAINING' then 1 end) AS `training_issues`, count(case when `csr`.`issue_type` = 'MAINTENANCE' then 1 end) AS `maintenance_issues`, count(case when `csr`.`priority` = 'HIGH' then 1 end) AS `high_priority`, count(case when `csr`.`priority` = 'MEDIUM' then 1 end) AS `medium_priority` FROM `classroom_support_records` AS `csr` WHERE `csr`.`is_deleted` = 0 GROUP BY `csr`.`support_date` ORDER BY `csr`.`support_date` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `view_device_lifetime_stats`
--
DROP TABLE IF EXISTS `view_device_lifetime_stats`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_device_lifetime_stats`  AS SELECT `d`.`device_id` AS `device_id`, `d`.`device_unique_id` AS `device_unique_id`, `dt`.`type_name` AS `type_name`, `db`.`brand_name` AS `brand_name`, `d`.`model` AS `model`, min(`di`.`installed_date`) AS `first_installation_date`, to_days(curdate()) - to_days(min(`di`.`installed_date`)) AS `total_lifetime_days`, count(distinct `di`.`installation_id`) AS `total_installations`, count(distinct `di`.`room_id`) AS `total_rooms_used` FROM (((`devices` `d` left join `device_types` `dt` on(`d`.`type_id` = `dt`.`type_id`)) left join `device_brands` `db` on(`d`.`brand_id` = `db`.`brand_id`)) left join `device_installations` `di` on(`d`.`device_id` = `di`.`device_id` and `di`.`is_deleted` = 0)) WHERE `d`.`is_deleted` = 0 GROUP BY `d`.`device_id`, `d`.`device_unique_id`, `dt`.`type_name`, `db`.`brand_name`, `d`.`model` ;

-- --------------------------------------------------------

--
-- Structure for view `view_excel_active_installations`
--
DROP TABLE IF EXISTS `view_excel_active_installations`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_excel_active_installations`  AS SELECT `r`.`room_number` AS `ID`, `r`.`building` AS `Location`, `db`.`brand_name` AS `Multimedia Brand`, `d`.`device_status` AS `Status`, `d`.`device_unique_id` AS `NSU ID`, `d`.`serial_number` AS `Manufacture SL`, `di`.`installed_date` AS `Install Date`, `di`.`installation_type` AS `Installation Type`, `di`.`team_members` AS `TEAM`, `d`.`current_issue` AS `Current Issue`, `d`.`storage_location` AS `Storage` FROM (((`device_installations` `di` join `devices` `d` on(`di`.`device_id` = `d`.`device_id`)) join `device_brands` `db` on(`d`.`brand_id` = `db`.`brand_id`)) join `rooms` `r` on(`di`.`room_id` = `r`.`room_id`)) WHERE `di`.`status` = 'active' AND `di`.`is_deleted` = 0 AND `d`.`is_deleted` = 0 ORDER BY `r`.`room_number` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `view_excel_withdrawn_devices`
--
DROP TABLE IF EXISTS `view_excel_withdrawn_devices`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_excel_withdrawn_devices`  AS SELECT `d`.`device_unique_id` AS `NSU ID`, `db`.`brand_name` AS `Status/Brand`, `d`.`serial_number` AS `Manufacture SL`, `d`.`current_issue` AS `Issue`, `d`.`storage_location` AS `Store`, `di`.`withdrawn_date` AS `Withdrawn Date`, `di`.`issue_at_withdrawal` AS `Withdrawal Issue`, `di`.`withdrawal_notes` AS `Notes` FROM ((`devices` `d` join `device_brands` `db` on(`d`.`brand_id` = `db`.`brand_id`)) left join `device_installations` `di` on(`d`.`device_id` = `di`.`device_id` and `di`.`status` = 'withdrawn' and `di`.`is_deleted` = 0)) WHERE (`d`.`device_status` = 'WITHDRAWN' OR `di`.`status` = 'withdrawn') AND `d`.`is_deleted` = 0 ORDER BY `di`.`withdrawn_date` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `view_support_statistics`
--
DROP TABLE IF EXISTS `view_support_statistics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_support_statistics`  AS SELECT `stm`.`member_id` AS `member_id`, `stm`.`member_name` AS `member_name`, `stm`.`department` AS `department`, count(`csr`.`support_id`) AS `total_supports`, count(case when `csr`.`support_date` >= curdate() - interval 30 day then 1 end) AS `supports_last_30_days`, count(case when `csr`.`support_date` >= curdate() - interval 7 day then 1 end) AS `supports_last_7_days`, sum(case when `csr`.`duration_minutes` is not null then `csr`.`duration_minutes` else 0 end) AS `total_minutes`, avg(case when `csr`.`duration_minutes` is not null then `csr`.`duration_minutes` else NULL end) AS `avg_duration_minutes`, max(`csr`.`support_date`) AS `last_support_date` FROM (`support_team_members` `stm` left join `classroom_support_records` `csr` on(`stm`.`member_id` = `csr`.`member_id` and `csr`.`is_deleted` = 0)) WHERE `stm`.`is_active` = 1 GROUP BY `stm`.`member_id`, `stm`.`member_name`, `stm`.`department` ;

-- --------------------------------------------------------

--
-- Structure for view `v_device_installation_history`
--
DROP TABLE IF EXISTS `v_device_installation_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_device_installation_history`  AS SELECT `di`.`installation_id` AS `installation_id`, `di`.`device_id` AS `device_id`, `d`.`device_unique_id` AS `device_unique_id`, `dt`.`type_name` AS `type_name`, `db`.`brand_name` AS `brand_name`, `d`.`model` AS `model`, `di`.`room_id` AS `room_id`, `r`.`room_number` AS `room_number`, `r`.`room_name` AS `room_name`, `r`.`building` AS `building`, `r`.`floor` AS `floor`, `di`.`installed_date` AS `installed_date`, `di`.`withdrawn_date` AS `withdrawn_date`, `di`.`status` AS `status`, `di`.`installation_notes` AS `installation_notes`, `di`.`withdrawal_notes` AS `withdrawal_notes`, `di`.`gate_pass_number` AS `gate_pass_number`, `di`.`gate_pass_date` AS `gate_pass_date`, to_days(coalesce(`di`.`withdrawn_date`,curdate())) - to_days(`di`.`installed_date`) AS `days_in_room`, coalesce(`di`.`installer_name`,`u1`.`full_name`) AS `installed_by_name`, `di`.`installer_id` AS `installed_by_id`, coalesce(`di`.`withdrawer_name`,`u2`.`full_name`) AS `withdrawn_by_name`, `di`.`withdrawer_id` AS `withdrawn_by_id`, `u3`.`full_name` AS `data_entry_by_name`, `u3`.`username` AS `data_entry_username`, `di`.`created_at` AS `created_at`, `di`.`updated_at` AS `updated_at` FROM (((((((`device_installations` `di` join `devices` `d` on(`di`.`device_id` = `d`.`device_id`)) join `device_types` `dt` on(`d`.`type_id` = `dt`.`type_id`)) join `device_brands` `db` on(`d`.`brand_id` = `db`.`brand_id`)) join `rooms` `r` on(`di`.`room_id` = `r`.`room_id`)) left join `users` `u1` on(`di`.`installed_by` = `u1`.`user_id`)) left join `users` `u2` on(`di`.`withdrawn_by` = `u2`.`user_id`)) left join `users` `u3` on(`di`.`data_entry_by` = `u3`.`user_id`)) WHERE `di`.`is_deleted` = 0 ORDER BY `di`.`installed_date` DESC ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_table_name` (`table_name`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `blog_categories`
--
ALTER TABLE `blog_categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `category_name` (`category_name`),
  ADD UNIQUE KEY `category_slug` (`category_slug`),
  ADD KEY `idx_slug` (`category_slug`);

--
-- Indexes for table `blog_comments`
--
ALTER TABLE `blog_comments`
  ADD PRIMARY KEY (`comment_id`),
  ADD KEY `idx_post` (`post_id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_parent` (`parent_comment_id`),
  ADD KEY `idx_deleted` (`is_deleted`);

--
-- Indexes for table `blog_posts`
--
ALTER TABLE `blog_posts`
  ADD PRIMARY KEY (`post_id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `idx_slug` (`slug`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_published_at` (`published_at`),
  ADD KEY `idx_category` (`category_id`),
  ADD KEY `idx_author` (`author_id`);
ALTER TABLE `blog_posts` ADD FULLTEXT KEY `idx_search` (`title`,`content`,`excerpt`);

--
-- Indexes for table `blog_reactions`
--
ALTER TABLE `blog_reactions`
  ADD PRIMARY KEY (`reaction_id`),
  ADD UNIQUE KEY `unique_user_post` (`post_id`,`user_id`),
  ADD KEY `idx_post` (`post_id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_type` (`reaction_type`);

--
-- Indexes for table `classroom_support_records`
--
ALTER TABLE `classroom_support_records`
  ADD PRIMARY KEY (`support_id`),
  ADD KEY `room_id` (`room_id`),
  ADD KEY `deleted_by` (`deleted_by`),
  ADD KEY `idx_member_id` (`member_id`),
  ADD KEY `idx_support_date` (`support_date`),
  ADD KEY `idx_location` (`location`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_is_deleted` (`is_deleted`),
  ADD KEY `idx_created_by` (`created_by`);

--
-- Indexes for table `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`device_id`),
  ADD UNIQUE KEY `device_unique_id` (`device_unique_id`),
  ADD KEY `deleted_by` (`deleted_by`),
  ADD KEY `idx_device_unique_id` (`device_unique_id`),
  ADD KEY `idx_type_id` (`type_id`),
  ADD KEY `idx_brand_id` (`brand_id`),
  ADD KEY `idx_is_deleted` (`is_deleted`),
  ADD KEY `idx_devices_active` (`is_active`,`is_deleted`),
  ADD KEY `idx_device_status` (`device_status`),
  ADD KEY `idx_storage_location` (`storage_location`);

--
-- Indexes for table `device_brands`
--
ALTER TABLE `device_brands`
  ADD PRIMARY KEY (`brand_id`),
  ADD UNIQUE KEY `brand_name` (`brand_name`);

--
-- Indexes for table `device_installations`
--
ALTER TABLE `device_installations`
  ADD PRIMARY KEY (`installation_id`),
  ADD KEY `installed_by` (`installed_by`),
  ADD KEY `withdrawn_by` (`withdrawn_by`),
  ADD KEY `deleted_by` (`deleted_by`),
  ADD KEY `idx_device_id` (`device_id`),
  ADD KEY `idx_room_id` (`room_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_installed_date` (`installed_date`),
  ADD KEY `idx_is_deleted` (`is_deleted`),
  ADD KEY `idx_installations_active` (`status`,`is_deleted`),
  ADD KEY `fk_data_entry_user` (`data_entry_by`),
  ADD KEY `idx_gate_pass_number` (`gate_pass_number`);

--
-- Indexes for table `device_issues`
--
ALTER TABLE `device_issues`
  ADD PRIMARY KEY (`issue_id`),
  ADD UNIQUE KEY `issue_name` (`issue_name`);

--
-- Indexes for table `device_types`
--
ALTER TABLE `device_types`
  ADD PRIMARY KEY (`type_id`),
  ADD UNIQUE KEY `type_name` (`type_name`);

--
-- Indexes for table `gate_passes`
--
ALTER TABLE `gate_passes`
  ADD PRIMARY KEY (`gate_pass_id`),
  ADD UNIQUE KEY `gate_pass_number` (`gate_pass_number`),
  ADD KEY `destination_room_id` (`destination_room_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `deleted_by` (`deleted_by`),
  ADD KEY `idx_gate_pass_number` (`gate_pass_number`),
  ADD KEY `idx_gate_pass_date` (`gate_pass_date`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `gate_pass_devices`
--
ALTER TABLE `gate_pass_devices`
  ADD PRIMARY KEY (`gate_pass_device_id`),
  ADD UNIQUE KEY `unique_gate_pass_device` (`gate_pass_id`,`device_id`),
  ADD KEY `device_id` (`device_id`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`room_id`),
  ADD UNIQUE KEY `room_number` (`room_number`),
  ADD KEY `idx_room_number` (`room_number`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`session_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_last_activity` (`last_activity`);

--
-- Indexes for table `storage_locations`
--
ALTER TABLE `storage_locations`
  ADD PRIMARY KEY (`location_id`),
  ADD UNIQUE KEY `location_name` (`location_name`);

--
-- Indexes for table `support_team_members`
--
ALTER TABLE `support_team_members`
  ADD PRIMARY KEY (`member_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_member_name` (`member_name`),
  ADD KEY `idx_is_active` (`is_active`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_role` (`role`),
  ADD KEY `idx_user_role_active` (`role`,`is_active`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=418;

--
-- AUTO_INCREMENT for table `blog_categories`
--
ALTER TABLE `blog_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `blog_comments`
--
ALTER TABLE `blog_comments`
  MODIFY `comment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `blog_posts`
--
ALTER TABLE `blog_posts`
  MODIFY `post_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `blog_reactions`
--
ALTER TABLE `blog_reactions`
  MODIFY `reaction_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `classroom_support_records`
--
ALTER TABLE `classroom_support_records`
  MODIFY `support_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `devices`
--
ALTER TABLE `devices`
  MODIFY `device_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=235;

--
-- AUTO_INCREMENT for table `device_brands`
--
ALTER TABLE `device_brands`
  MODIFY `brand_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `device_installations`
--
ALTER TABLE `device_installations`
  MODIFY `installation_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=187;

--
-- AUTO_INCREMENT for table `device_issues`
--
ALTER TABLE `device_issues`
  MODIFY `issue_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `device_types`
--
ALTER TABLE `device_types`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `gate_passes`
--
ALTER TABLE `gate_passes`
  MODIFY `gate_pass_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `gate_pass_devices`
--
ALTER TABLE `gate_pass_devices`
  MODIFY `gate_pass_device_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=160;

--
-- AUTO_INCREMENT for table `storage_locations`
--
ALTER TABLE `storage_locations`
  MODIFY `location_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `support_team_members`
--
ALTER TABLE `support_team_members`
  MODIFY `member_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD CONSTRAINT `audit_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `blog_comments`
--
ALTER TABLE `blog_comments`
  ADD CONSTRAINT `blog_comments_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `blog_posts` (`post_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `blog_comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `blog_comments_ibfk_3` FOREIGN KEY (`parent_comment_id`) REFERENCES `blog_comments` (`comment_id`) ON DELETE CASCADE;

--
-- Constraints for table `blog_posts`
--
ALTER TABLE `blog_posts`
  ADD CONSTRAINT `blog_posts_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `blog_categories` (`category_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `blog_posts_ibfk_2` FOREIGN KEY (`author_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `blog_reactions`
--
ALTER TABLE `blog_reactions`
  ADD CONSTRAINT `blog_reactions_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `blog_posts` (`post_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `blog_reactions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `classroom_support_records`
--
ALTER TABLE `classroom_support_records`
  ADD CONSTRAINT `classroom_support_records_ibfk_1` FOREIGN KEY (`member_id`) REFERENCES `support_team_members` (`member_id`),
  ADD CONSTRAINT `classroom_support_records_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `classroom_support_records_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `classroom_support_records_ibfk_4` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `devices`
--
ALTER TABLE `devices`
  ADD CONSTRAINT `devices_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `device_types` (`type_id`),
  ADD CONSTRAINT `devices_ibfk_2` FOREIGN KEY (`brand_id`) REFERENCES `device_brands` (`brand_id`),
  ADD CONSTRAINT `devices_ibfk_3` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `device_installations`
--
ALTER TABLE `device_installations`
  ADD CONSTRAINT `device_installations_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`),
  ADD CONSTRAINT `device_installations_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`),
  ADD CONSTRAINT `device_installations_ibfk_3` FOREIGN KEY (`installed_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `device_installations_ibfk_4` FOREIGN KEY (`withdrawn_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `device_installations_ibfk_5` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_data_entry_user` FOREIGN KEY (`data_entry_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `gate_passes`
--
ALTER TABLE `gate_passes`
  ADD CONSTRAINT `gate_passes_ibfk_2` FOREIGN KEY (`destination_room_id`) REFERENCES `rooms` (`room_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `gate_passes_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `gate_passes_ibfk_4` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `gate_pass_devices`
--
ALTER TABLE `gate_pass_devices`
  ADD CONSTRAINT `gate_pass_devices_ibfk_1` FOREIGN KEY (`gate_pass_id`) REFERENCES `gate_passes` (`gate_pass_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `gate_pass_devices_ibfk_2` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE;

--
-- Constraints for table `sessions`
--
ALTER TABLE `sessions`
  ADD CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `support_team_members`
--
ALTER TABLE `support_team_members`
  ADD CONSTRAINT `support_team_members_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `support_team_members_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
