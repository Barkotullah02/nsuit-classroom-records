-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jan 20, 2026 at 09:31 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.0.28

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
(36, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2026-01-20 07:50:19');

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
(49, '50-ITD-00508-00542', 10, 22, NULL, 'NEW', NULL, NULL, 'XZC253501137', NULL, NULL, NULL, 1, 0, NULL, NULL, '2026-01-15 10:50:12', '2026-01-15 10:50:12');

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
(22, 'VIEWSONIC', '2026-01-15 10:50:07');

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
(10, 'Multimedia Projector', 'Auto-created from CSV import', '2026-01-15 10:50:07');

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
(28, 'LIB 602', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-15 10:41:00'),
(29, 'LIB 603', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-15 10:41:00'),
(30, 'LIB 605', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-15 10:41:00'),
(31, 'LIB 609', 'Classroom', NULL, NULL, NULL, 1, '2026-01-15 10:41:00', '2026-01-15 10:41:00'),
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
(42, 'SAC 401', 'LAB Room', NULL, NULL, NULL, 1, '2026-01-15 10:41:02', '2026-01-15 10:41:02');

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
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

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
  MODIFY `device_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT for table `device_brands`
--
ALTER TABLE `device_brands`
  MODIFY `brand_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `device_installations`
--
ALTER TABLE `device_installations`
  MODIFY `installation_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `device_issues`
--
ALTER TABLE `device_issues`
  MODIFY `issue_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `device_types`
--
ALTER TABLE `device_types`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

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
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

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
