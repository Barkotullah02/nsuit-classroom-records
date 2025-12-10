-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Dec 10, 2025 at 08:45 AM
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
(1, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:13:46'),
(2, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:14:22'),
(3, 2, 'LOGIN', 'users', 2, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:14:48'),
(4, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:16:47'),
(5, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:16:59'),
(6, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', '2025-11-28 16:22:53'),
(7, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:31:16'),
(8, 2, 'LOGIN', 'users', 2, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:31:16'),
(9, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:31:26'),
(10, 2, 'LOGIN', 'users', 2, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:31:28'),
(11, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:32:09'),
(12, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:32:49'),
(13, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:33:12'),
(14, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:33:30'),
(15, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 16:33:49'),
(16, 1, 'CREATE', 'devices', 1, NULL, '{\"device_unique_id\":\"dfrgggggh34\",\"type_id\":\"1\",\"brand_id\":\"2\",\"model\":\"drgt\",\"serial_number\":\"dfgd\",\"purchase_date\":\"2025-11-29\",\"warranty_period\":\"3\",\"notes\":\"trrryt\"}', NULL, NULL, '2025-11-28 18:09:39'),
(17, 1, 'CREATE', 'device_installations', 1, NULL, '{\"device_id\":\"1\",\"room_id\":\"10\",\"installed_date\":\"2025-11-28\",\"installation_notes\":\"erg. e er eg\"}', NULL, NULL, '2025-11-28 18:10:09'),
(18, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 18:13:15'),
(19, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-11-28 18:16:17'),
(20, 1, 'SOFT_DELETE', 'devices', 1, NULL, NULL, NULL, NULL, '2025-11-28 18:21:54'),
(21, 1, 'CREATE', 'devices', 2, NULL, '{\"device_unique_id\":\"jgujg kihlioh lo\",\"type_id\":\"1\",\"brand_id\":\"1\",\"model\":\"jugiu g\",\"serial_number\":\"ugihy\",\"purchase_date\":\"2025-11-29\",\"warranty_period\":\"23\",\"notes\":\"utku\"}', NULL, NULL, '2025-11-29 04:09:45'),
(22, 1, 'CREATE', 'device_installations', 2, NULL, '{\"device_id\":\"2\",\"room_id\":\"11\",\"installed_date\":\"2025-11-29\",\"installation_notes\":\"\"}', NULL, NULL, '2025-11-29 04:10:34'),
(23, 1, 'UPDATE', 'device_installations', 2, '{\"installation_id\":2,\"device_id\":2,\"room_id\":11,\"installed_date\":\"2025-11-29\",\"withdrawn_date\":null,\"installed_by\":1,\"withdrawn_by\":null,\"installation_notes\":\"\",\"withdrawal_notes\":null,\"status\":\"active\",\"is_deleted\":0,\"deleted_at\":null,\"deleted_by\":null,\"created_at\":\"2025-11-29 10:10:34\",\"updated_at\":\"2025-11-29 10:10:34\"}', '{\"installation_id\":\"2\",\"withdrawn_date\":\"2025-11-29\",\"withdrawal_notes\":\"\"}', NULL, NULL, '2025-11-29 04:10:59'),
(24, 1, 'CREATE', 'device_installations', 3, NULL, '{\"device_id\":\"2\",\"room_id\":\"12\",\"installed_date\":\"2025-11-29\",\"installation_notes\":\"\"}', NULL, NULL, '2025-11-29 04:11:28'),
(25, 1, 'CREATE', 'devices', 3, NULL, '{\"device_unique_id\":\"AD DWWQ\",\"type_id\":\"2\",\"brand_id\":\"4\",\"model\":\"zsv\",\"serial_number\":\"awff\",\"purchase_date\":\"2025-11-29\",\"warranty_period\":\"20\",\"notes\":\"afesd\"}', NULL, NULL, '2025-11-29 05:25:58'),
(26, 1, 'INSERT', 'gate_passes', 1, NULL, NULL, NULL, NULL, '2025-11-29 06:39:31'),
(27, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36', '2025-11-30 06:41:44'),
(28, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36', '2025-12-02 03:21:10'),
(29, 1, 'CREATE', 'devices', 4, NULL, '{\"device_unique_id\":\"hjbj iuh8ih 8\",\"type_id\":\"2\",\"brand_id\":\"3\",\"model\":\"gfcytui\",\"serial_number\":\"kiuhioho\",\"purchase_date\":\"2025-12-02\",\"warranty_period\":\"45\",\"notes\":\"kjb iuh oih. ohj9jhjp\"}', NULL, NULL, '2025-12-02 05:55:40'),
(30, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-12-02 06:56:26'),
(31, 1, 'RESTORE', 'devices', 1, NULL, NULL, NULL, NULL, '2025-12-02 07:05:04'),
(32, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-12-02 07:08:21'),
(33, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36', '2025-12-03 08:10:47'),
(34, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2025-12-09 06:12:15'),
(35, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36', '2025-12-09 07:28:32'),
(36, 1, 'LOGIN', 'users', 1, NULL, NULL, '127.0.0.1', 'curl/8.7.1', '2025-12-09 08:53:10'),
(37, 1, 'CREATE', 'devices', 5, NULL, '{\"device_unique_id\":\"DEV004\",\"type_id\":\"2\",\"brand_id\":\"8\",\"model\":\"S24R350\",\"serial_number\":\"SN654321987\",\"purchase_date\":\"2024-03-05\",\"warranty_period\":\"24\",\"notes\":\"Lab monitor\"}', NULL, NULL, '2025-12-09 09:05:02'),
(38, 1, 'CREATE', 'devices', 6, NULL, '{\"device_unique_id\":\"50-ITD-0508-00545\",\"type_id\":\"1\",\"brand_id\":\"16\",\"model\":\"OptiPlex 7090\",\"serial_number\":\"XZC253501179\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"36\",\"notes\":\"Computer lab desktop\"}', NULL, NULL, '2025-12-09 09:13:40'),
(39, 1, 'CREATE', 'devices', 7, NULL, '{\"device_unique_id\":\"50-ITD-0508-00544\",\"type_id\":\"1\",\"brand_id\":\"17\",\"model\":\"OptiPlex 7091\",\"serial_number\":\"XZC253201181\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"24\",\"notes\":\"Faculty laptop\"}', NULL, NULL, '2025-12-09 09:13:40'),
(40, 1, 'CREATE', 'devices', 8, NULL, '{\"device_unique_id\":\"50-ITD-0508-00543\",\"type_id\":\"1\",\"brand_id\":\"17\",\"model\":\"OptiPlex 7092\",\"serial_number\":\"XZC253201215\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"12\",\"notes\":\"Classroom projector\"}', NULL, NULL, '2025-12-09 09:13:40'),
(41, 1, 'CREATE', 'devices', 9, NULL, '{\"device_unique_id\":\"50-ITD-0508-00547\",\"type_id\":\"1\",\"brand_id\":\"17\",\"model\":\"OptiPlex 7093\",\"serial_number\":\"XZC253201224\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"24\",\"notes\":\"Lab monitor\"}', NULL, NULL, '2025-12-09 09:13:40'),
(42, 1, 'CREATE', 'devices', 10, NULL, '{\"device_unique_id\":\"50-ITD-0508-0327\",\"type_id\":\"1\",\"brand_id\":\"17\",\"model\":\"OptiPlex 7094\",\"serial_number\":\"F9IE03694\",\"purchase_date\":\"12\\/2\\/25\",\"warranty_period\":\"12\",\"notes\":\"Office printer\"}', NULL, NULL, '2025-12-09 09:13:40'),
(43, 1, 'CREATE', 'devices', 11, NULL, '{\"device_unique_id\":\"50-ITD-0508-284\",\"type_id\":\"1\",\"brand_id\":\"18\",\"model\":\"OptiPlex 7095\",\"serial_number\":\"F9GE01947\",\"purchase_date\":\"12\\/2\\/25\",\"warranty_period\":\"7.2\",\"notes\":\"Computer lab desktop\"}', NULL, NULL, '2025-12-09 09:13:40'),
(44, 1, 'CREATE', 'devices', 12, NULL, '{\"device_unique_id\":\"50-ITD-0508-00537\",\"type_id\":\"1\",\"brand_id\":\"18\",\"model\":\"OptiPlex 7096\",\"serial_number\":\"XZC250301029\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"2.4\",\"notes\":\"Faculty laptop\"}', NULL, NULL, '2025-12-09 09:13:41'),
(45, 1, 'CREATE', 'devices', 13, NULL, '{\"device_unique_id\":\"50-ITD-0508-N\\/A\",\"type_id\":\"1\",\"brand_id\":\"17\",\"model\":\"OptiPlex 7097\",\"serial_number\":\"F1LE14628\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"2.4\",\"notes\":\"Classroom projector\"}', NULL, NULL, '2025-12-09 09:13:41'),
(46, 1, 'CREATE', 'devices', 14, NULL, '{\"device_unique_id\":\"50-ITD-0508-0349\",\"type_id\":\"1\",\"brand_id\":\"18\",\"model\":\"OptiPlex 7098\",\"serial_number\":\"F1AE09532\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"7.2\",\"notes\":\"Lab monitor\"}', NULL, NULL, '2025-12-09 09:13:41'),
(47, 1, 'CREATE', 'devices', 15, NULL, '{\"device_unique_id\":\"50-ITD-00508-00460\",\"type_id\":\"1\",\"brand_id\":\"18\",\"model\":\"OptiPlex 7099\",\"serial_number\":\"PDA7P01402000\",\"purchase_date\":\"12\\/1\\/25\",\"warranty_period\":\"12\",\"notes\":\"Office printer\"}', NULL, NULL, '2025-12-09 09:13:41');

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

--
-- Dumping data for table `blog_categories`
--

INSERT INTO `blog_categories` (`category_id`, `category_name`, `category_slug`, `description`, `created_at`) VALUES
(1, 'Announcements', 'announcements', 'Important announcements and updates', '2025-12-02 06:45:28'),
(2, 'Events', 'events', 'Upcoming and past events', '2025-12-02 06:45:28'),
(3, 'Maintenance', 'maintenance', 'System and device maintenance updates', '2025-12-02 06:45:28'),
(4, 'News', 'news', 'Latest news and information', '2025-12-02 06:45:28'),
(5, 'Tips & Tricks', 'tips-tricks', 'Helpful tips for device management', '2025-12-02 06:45:28');

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

--
-- Dumping data for table `blog_comments`
--

INSERT INTO `blog_comments` (`comment_id`, `post_id`, `user_id`, `parent_comment_id`, `comment_text`, `is_deleted`, `created_at`, `updated_at`) VALUES
(1, 1, 1, NULL, 'This is fantastic! Looking forward to more updates.', 0, '2025-12-02 06:57:26', '2025-12-02 06:57:26');

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

--
-- Dumping data for table `blog_posts`
--

INSERT INTO `blog_posts` (`post_id`, `title`, `slug`, `content`, `excerpt`, `category_id`, `author_id`, `featured_image`, `status`, `view_count`, `is_pinned`, `published_at`, `created_at`, `updated_at`) VALUES
(1, 'Welcome to NSU IT Classroom Blog', 'welcome-to-nsu-it-classroom-blog', 'This is our first blog post! We are excited to share updates, news, and announcements with you all. Stay tuned for more content about upcoming events, maintenance schedules, and helpful tips & tricks for using our classroom devices.', 'Welcome to our new blog platform where we share updates and announcements.', 1, 1, NULL, 'published', 0, 0, '2025-12-02 01:56:36', '2025-12-02 06:56:36', '2025-12-02 06:56:36'),
(2, 'Upcoming Tech Fest 2025', 'upcoming-tech-fest-2025', 'We are thrilled to announce the NSU IT Tech Fest 2025! Join us for three days of workshops, competitions, and networking. Event dates: March 15-17, 2025. Register now at the IT office. Topics include: AI/ML workshops, coding competitions, hackathons, and industry expert talks. Prizes worth $5000!', 'Join us for NSU IT Tech Fest 2025 - three days of technology, learning, and fun!', 2, 1, NULL, 'published', 0, 0, '2025-12-02 01:56:54', '2025-12-02 06:56:54', '2025-12-02 06:56:54'),
(3, 'Lab Maintenance Scheduled', 'lab-maintenance-scheduled', 'Please be informed that Lab A and Lab B will undergo scheduled maintenance on February 10, 2025, from 9:00 AM to 2:00 PM. During this time, all devices will be unavailable. We will be updating software, replacing faulty equipment, and performing network upgrades. Classes scheduled during this time have been moved to Lab C. Thank you for your cooperation.', 'Lab A and B maintenance scheduled for Feb 10, 2025.', 3, 1, NULL, 'published', 0, 0, '2025-12-02 01:56:54', '2025-12-02 06:56:54', '2025-12-02 06:56:54');

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

--
-- Dumping data for table `blog_reactions`
--

INSERT INTO `blog_reactions` (`reaction_id`, `post_id`, `user_id`, `reaction_type`, `created_at`) VALUES
(1, 1, 1, 'love', '2025-12-02 06:57:26');

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
  `serial_number` varchar(100) DEFAULT NULL,
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

INSERT INTO `devices` (`device_id`, `device_unique_id`, `type_id`, `brand_id`, `model`, `serial_number`, `purchase_date`, `warranty_period`, `notes`, `is_active`, `is_deleted`, `deleted_at`, `deleted_by`, `created_at`, `updated_at`) VALUES
(1, 'dfrgggggh34', 1, 2, 'drgt', 'dfgd', '2025-11-29', 3, 'trrryt', 1, 0, NULL, NULL, '2025-11-28 18:09:39', '2025-12-02 07:05:04'),
(2, 'jgujg kihlioh lo', 1, 1, 'jugiu g', 'ugihy', '2025-11-29', 23, 'utku', 1, 0, NULL, NULL, '2025-11-29 04:09:45', '2025-11-29 04:09:45'),
(3, 'AD DWWQ', 2, 4, 'zsv', 'awff', '2025-11-29', 20, 'afesd', 1, 0, NULL, NULL, '2025-11-29 05:25:58', '2025-11-29 05:25:58'),
(4, 'hjbj iuh8ih 8', 2, 3, 'gfcytui', 'kiuhioho', '2025-12-02', 45, 'kjb iuh oih. ohj9jhjp', 1, 0, NULL, NULL, '2025-12-02 05:55:40', '2025-12-02 05:55:40'),
(5, 'DEV004', 2, 8, 'S24R350', 'SN654321987', '2024-03-05', 24, 'Lab monitor', 1, 0, NULL, NULL, '2025-12-09 09:05:02', '2025-12-09 09:05:02'),
(6, '50-ITD-0508-00545', 1, 16, 'OptiPlex 7090', 'XZC253501179', '2012-01-25', 36, 'Computer lab desktop', 1, 0, NULL, NULL, '2025-12-09 09:13:40', '2025-12-09 09:13:40'),
(7, '50-ITD-0508-00544', 1, 17, 'OptiPlex 7091', 'XZC253201181', '2012-01-25', 24, 'Faculty laptop', 1, 0, NULL, NULL, '2025-12-09 09:13:40', '2025-12-09 09:13:40'),
(8, '50-ITD-0508-00543', 1, 17, 'OptiPlex 7092', 'XZC253201215', '2012-01-25', 12, 'Classroom projector', 1, 0, NULL, NULL, '2025-12-09 09:13:40', '2025-12-09 09:13:40'),
(9, '50-ITD-0508-00547', 1, 17, 'OptiPlex 7093', 'XZC253201224', '2012-01-25', 24, 'Lab monitor', 1, 0, NULL, NULL, '2025-12-09 09:13:40', '2025-12-09 09:13:40'),
(10, '50-ITD-0508-0327', 1, 17, 'OptiPlex 7094', 'F9IE03694', '2012-02-25', 12, 'Office printer', 1, 0, NULL, NULL, '2025-12-09 09:13:40', '2025-12-09 09:13:40'),
(11, '50-ITD-0508-284', 1, 18, 'OptiPlex 7095', 'F9GE01947', '2012-02-25', 7, 'Computer lab desktop', 1, 0, NULL, NULL, '2025-12-09 09:13:40', '2025-12-09 09:13:40'),
(12, '50-ITD-0508-00537', 1, 18, 'OptiPlex 7096', 'XZC250301029', '2012-01-25', 2, 'Faculty laptop', 1, 0, NULL, NULL, '2025-12-09 09:13:41', '2025-12-09 09:13:41'),
(13, '50-ITD-0508-N/A', 1, 17, 'OptiPlex 7097', 'F1LE14628', '2012-01-25', 2, 'Classroom projector', 1, 0, NULL, NULL, '2025-12-09 09:13:41', '2025-12-09 09:13:41'),
(14, '50-ITD-0508-0349', 1, 18, 'OptiPlex 7098', 'F1AE09532', '2012-01-25', 7, 'Lab monitor', 1, 0, NULL, NULL, '2025-12-09 09:13:41', '2025-12-09 09:13:41'),
(15, '50-ITD-00508-00460', 1, 18, 'OptiPlex 7099', 'PDA7P01402000', '2012-01-25', 12, 'Office printer', 1, 0, NULL, NULL, '2025-12-09 09:13:41', '2025-12-09 09:13:41');

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
(1, 'HP', '2025-11-28 16:02:13'),
(2, 'Boxlight', '2025-11-28 16:02:13'),
(3, 'A4Tech', '2025-11-28 16:02:13'),
(4, 'Dell', '2025-11-28 16:02:13'),
(5, 'Logitech', '2025-11-28 16:02:13'),
(6, 'Sony', '2025-11-28 16:02:13'),
(7, 'Epson', '2025-11-28 16:02:13'),
(8, 'Samsung', '2025-11-28 16:02:13'),
(9, 'LG', '2025-11-28 16:02:13'),
(10, 'Microsoft', '2025-11-28 16:02:13'),
(11, 'Test Brand', '2025-11-28 16:31:16'),
(14, 'New Brand 123', '2025-11-28 16:32:50'),
(15, 'TestBrand', '2025-11-28 16:33:12'),
(16, 'BENQ', '2025-12-09 09:13:40'),
(17, 'VIEW SONIC', '2025-12-09 09:13:40'),
(18, 'MAXELL', '2025-12-09 09:13:40');

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

INSERT INTO `device_installations` (`installation_id`, `device_id`, `room_id`, `installed_date`, `withdrawn_date`, `installed_by`, `installer_name`, `installer_id`, `withdrawn_by`, `withdrawer_name`, `withdrawer_id`, `data_entry_by`, `gate_pass_number`, `gate_pass_date`, `installation_notes`, `withdrawal_notes`, `status`, `is_deleted`, `deleted_at`, `deleted_by`, `created_at`, `updated_at`) VALUES
(1, 1, 10, '2025-11-28', NULL, 1, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, 'erg. e er eg', NULL, 'active', 0, NULL, NULL, '2025-11-28 18:10:09', '2025-11-29 04:51:50'),
(2, 2, 11, '2025-11-29', '2025-11-29', 1, NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, '', '', 'withdrawn', 0, NULL, NULL, '2025-11-29 04:10:34', '2025-11-29 04:51:50'),
(3, 2, 12, '2025-11-29', NULL, 1, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, '', NULL, 'active', 0, NULL, NULL, '2025-11-29 04:11:28', '2025-11-29 04:51:50');

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
(1, 'Multimedia Projector', 'Digital multimedia projectors', '2025-11-28 16:02:13'),
(2, 'Monitor', 'Computer monitors and displays', '2025-11-28 16:02:13'),
(3, 'Speaker', 'Audio speakers and sound systems', '2025-11-28 16:02:13'),
(4, 'Keyboard', 'Computer keyboards', '2025-11-28 16:02:13'),
(5, 'Mouse', 'Computer mice and pointing devices', '2025-11-28 16:02:13'),
(6, 'Test Device Type', 'Test description', '2025-11-28 16:31:16'),
(8, 'Tablet', 'Touch screen tablets', '2025-11-28 16:33:31'),
(9, 'Webcam', 'Video cameras', '2025-11-28 16:33:49');

-- --------------------------------------------------------

--
-- Table structure for table `gate_passes`
--

CREATE TABLE `gate_passes` (
  `gate_pass_id` int(11) NOT NULL,
  `gate_pass_number` varchar(50) NOT NULL,
  `gate_pass_date` date NOT NULL,
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

--
-- Dumping data for table `gate_passes`
--

INSERT INTO `gate_passes` (`gate_pass_id`, `gate_pass_number`, `gate_pass_date`, `consignee_name`, `destination`, `destination_room_id`, `carrier_name`, `carrier_appointment`, `carrier_department`, `carrier_telephone`, `security_name`, `security_appointment`, `security_department`, `security_telephone`, `receiver_name`, `receiver_appointment`, `receiver_department`, `receiver_telephone`, `purpose`, `remarks`, `status`, `created_by`, `is_deleted`, `deleted_at`, `deleted_by`, `created_at`, `updated_at`) VALUES
(1, '931243', '2025-11-29', NULL, NULL, NULL, 'hjvu', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Other', 'fdghjhk', 'active', 1, 0, NULL, NULL, '2025-11-29 06:39:31', '2025-11-29 06:39:31');

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

--
-- Dumping data for table `gate_pass_devices`
--

INSERT INTO `gate_pass_devices` (`gate_pass_device_id`, `gate_pass_id`, `device_id`, `created_at`) VALUES
(1, 1, 3, '2025-11-29 07:06:25');

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
(1, 'R101', 'Computer Lab 1', 'Main Building', 1, 40, 0, '2025-11-28 16:02:13', '2025-12-02 04:41:08'),
(2, 'R102', 'Computer Lab 2', 'Main Building', 1, 40, 0, '2025-11-28 16:02:13', '2025-12-02 04:24:41'),
(3, 'R201', 'Conference Room', 'Main Building', 2, 20, 1, '2025-11-28 16:02:13', '2025-11-28 16:02:13'),
(4, 'R202', 'Training Room', 'Main Building', 2, 30, 0, '2025-11-28 16:02:13', '2025-12-02 05:08:41'),
(5, 'R301', 'Auditorium', 'Main Building', 3, 100, 0, '2025-11-28 16:02:13', '2025-12-02 07:04:49'),
(6, 'TEST-101', 'Test Room', 'Test Building', 1, 30, 0, '2025-11-28 16:31:16', '2025-12-02 05:47:33'),
(8, 'R-999', 'Test Lab', 'Main', 3, 25, 0, '2025-11-28 16:33:32', '2025-12-02 04:22:24'),
(9, 'L-505', 'Computer Lab 5', 'IT Building', 5, 40, 0, '2025-11-28 16:33:49', '2025-12-02 04:10:57'),
(10, 'SAC201', 'CLASSROOM', NULL, NULL, NULL, 1, '2025-11-28 18:08:36', '2025-11-28 18:08:36'),
(11, 'SAC505', 'CLASSROOM', NULL, NULL, NULL, 0, '2025-11-29 04:10:32', '2025-12-02 05:45:27'),
(12, 'SAC404', 'CLASSROOM', NULL, NULL, NULL, 1, '2025-11-29 04:11:20', '2025-11-29 04:11:20');

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

--
-- Dumping data for table `support_team_members`
--

INSERT INTO `support_team_members` (`member_id`, `user_id`, `member_name`, `member_email`, `member_phone`, `department`, `is_active`, `created_at`, `created_by`, `updated_at`) VALUES
(1, NULL, 'John Doe', 'john.doe@nsu.edu', NULL, 'IT Support', 1, '2025-12-09 07:23:53', NULL, '2025-12-09 07:23:53'),
(2, NULL, 'Jane Smith', 'jane.smith@nsu.edu', NULL, 'Technical Services', 1, '2025-12-09 07:23:53', NULL, '2025-12-09 07:23:53'),
(3, NULL, 'Mike Johnson', 'mike.johnson@nsu.edu', NULL, 'IT Support', 1, '2025-12-09 07:23:53', NULL, '2025-12-09 07:23:53');

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
  `role` enum('viewer','admin') DEFAULT 'viewer',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password_hash`, `full_name`, `email`, `role`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'admin', '$2y$12$LBWhJsqBDCbH0AG0uX1Iy.RHyfCyPL5cOP0ZfG73o/sFVnE.2/gIa', 'System Administrator', 'admin@classroom.local', 'admin', 1, '2025-11-28 16:02:13', '2025-11-28 16:13:41'),
(2, 'viewer', '$2y$12$LBWhJsqBDCbH0AG0uX1Iy.RHyfCyPL5cOP0ZfG73o/sFVnE.2/gIa', 'Guest Viewer', 'viewer@classroom.local', 'viewer', 1, '2025-11-28 16:02:13', '2025-11-28 16:13:41');

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
  ADD KEY `idx_devices_active` (`is_active`,`is_deleted`);

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
  ADD KEY `idx_role` (`role`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- AUTO_INCREMENT for table `blog_categories`
--
ALTER TABLE `blog_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `blog_comments`
--
ALTER TABLE `blog_comments`
  MODIFY `comment_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `blog_posts`
--
ALTER TABLE `blog_posts`
  MODIFY `post_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `blog_reactions`
--
ALTER TABLE `blog_reactions`
  MODIFY `reaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `classroom_support_records`
--
ALTER TABLE `classroom_support_records`
  MODIFY `support_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `devices`
--
ALTER TABLE `devices`
  MODIFY `device_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `device_brands`
--
ALTER TABLE `device_brands`
  MODIFY `brand_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `device_installations`
--
ALTER TABLE `device_installations`
  MODIFY `installation_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `device_types`
--
ALTER TABLE `device_types`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `gate_passes`
--
ALTER TABLE `gate_passes`
  MODIFY `gate_pass_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `gate_pass_devices`
--
ALTER TABLE `gate_pass_devices`
  MODIFY `gate_pass_device_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `support_team_members`
--
ALTER TABLE `support_team_members`
  MODIFY `member_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

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
