-- ============================================================================
-- CreativePOS — CRM, WhatsApp, Notifications, Audit, Reporting, Finance (31 tables)
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- CRM
CREATE TABLE `sla_policies` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `priority` ENUM('low','medium','high','critical') NOT NULL,
    `first_response_minutes` INT NOT NULL,
    `resolution_minutes` INT NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sla_policies_priority_tenant` (`priority`, `tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `support_tickets` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `ticket_number` VARCHAR(50) NOT NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `customer_name` VARCHAR(255) NULL,
    `customer_email` VARCHAR(255) NULL,
    `customer_phone` VARCHAR(20) NULL,
    `channel` ENUM('whatsapp','telegram','email','website','phone') NOT NULL,
    `subject` VARCHAR(255) NOT NULL,
    `priority` ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
    `status` ENUM('open','assigned','pending','resolved','closed') NOT NULL DEFAULT 'open',
    `assigned_to` BIGINT UNSIGNED NULL,
    `sla_deadline` TIMESTAMP NULL,
    `first_response_at` TIMESTAMP NULL,
    `resolved_at` TIMESTAMP NULL,
    `closed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_support_tickets_number` (`ticket_number`, `tenant_id`),
    KEY `idx_support_tickets_tenant` (`tenant_id`),
    KEY `idx_support_tickets_status` (`status`),
    KEY `idx_support_tickets_assigned` (`assigned_to`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ticket_messages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ticket_id` BIGINT UNSIGNED NOT NULL,
    `sender_type` ENUM('customer','agent','system') NOT NULL,
    `sender_id` BIGINT UNSIGNED NULL,
    `message` TEXT NOT NULL,
    `attachments` JSON NULL,
    `is_internal` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ticket_messages_ticket` (`ticket_id`),
    CONSTRAINT `fk_ticket_messages_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `support_tickets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ticket_assignments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ticket_id` BIGINT UNSIGNED NOT NULL,
    `assigned_to` BIGINT UNSIGNED NOT NULL,
    `assigned_by` BIGINT UNSIGNED NULL,
    `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `unassigned_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    KEY `idx_ticket_assignments_ticket` (`ticket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ticket_status_histories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ticket_id` BIGINT UNSIGNED NOT NULL,
    `from_status` VARCHAR(30) NULL,
    `to_status` VARCHAR(30) NOT NULL,
    `changed_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ticket_status_ticket` (`ticket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `knowledge_base_categories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `slug` VARCHAR(255) NOT NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_kb_categories_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `knowledge_base_articles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `category_id` BIGINT UNSIGNED NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `slug` VARCHAR(255) NOT NULL,
    `content` LONGTEXT NOT NULL,
    `is_published` TINYINT(1) NOT NULL DEFAULT 0,
    `view_count` INT NOT NULL DEFAULT 0,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_kb_articles_category` (`category_id`),
    KEY `idx_kb_articles_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `faqs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `question` VARCHAR(500) NOT NULL,
    `answer` TEXT NOT NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_faqs_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `canned_responses` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT NOT NULL,
    `shortcut` VARCHAR(50) NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_canned_responses_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `csat_surveys` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `ticket_id` BIGINT UNSIGNED NULL,
    `delivery_order_id` BIGINT UNSIGNED NULL,
    `rating` TINYINT NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
    `comment` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_csat_surveys_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- WHATSAPP
CREATE TABLE `whatsapp_configs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `provider` VARCHAR(50) NOT NULL,
    `phone_number_id` VARCHAR(100) NULL,
    `access_token` TEXT NULL,
    `webhook_verify_token` VARCHAR(255) NULL,
    `monthly_quota` INT NOT NULL DEFAULT 0,
    `used_quota` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_whatsapp_configs_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `whatsapp_templates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `template_id` VARCHAR(100) NULL,
    `category` ENUM('otp','invoice','reminder','loyalty','promo','delivery','custom') NOT NULL,
    `content` TEXT NOT NULL,
    `variables` JSON NULL,
    `status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_whatsapp_templates_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `whatsapp_messages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `template_id` BIGINT UNSIGNED NULL,
    `recipient_phone` VARCHAR(20) NOT NULL,
    `message` TEXT NOT NULL,
    `status` ENUM('queued','sent','delivered','read','failed') NOT NULL DEFAULT 'queued',
    `external_id` VARCHAR(255) NULL,
    `error_message` TEXT NULL,
    `sent_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_whatsapp_messages_tenant` (`tenant_id`),
    KEY `idx_whatsapp_messages_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `whatsapp_broadcasts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `template_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `status` ENUM('draft','scheduled','sending','completed','cancelled') NOT NULL DEFAULT 'draft',
    `scheduled_at` TIMESTAMP NULL,
    `total_recipients` INT NOT NULL DEFAULT 0,
    `sent_count` INT NOT NULL DEFAULT 0,
    `failed_count` INT NOT NULL DEFAULT 0,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_whatsapp_broadcasts_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `whatsapp_broadcast_recipients` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `broadcast_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `phone` VARCHAR(20) NOT NULL,
    `status` ENUM('pending','sent','failed') NOT NULL DEFAULT 'pending',
    `sent_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    KEY `idx_wa_broadcast_recipients_broadcast` (`broadcast_id`),
    CONSTRAINT `fk_wa_broadcast_recipients_broadcast` FOREIGN KEY (`broadcast_id`) REFERENCES `whatsapp_broadcasts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- NOTIFICATIONS
CREATE TABLE `notification_templates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NULL,
    `event` VARCHAR(100) NOT NULL,
    `channel` ENUM('email','whatsapp','push','in_app') NOT NULL,
    `subject` VARCHAR(255) NULL,
    `body` TEXT NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_notification_templates_event` (`event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `type` VARCHAR(100) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `body` TEXT NULL,
    `data` JSON NULL,
    `read_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_notifications_user` (`user_id`),
    KEY `idx_notifications_tenant` (`tenant_id`),
    KEY `idx_notifications_read` (`read_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_notification_preferences` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `channel` ENUM('email','whatsapp','push','in_app') NOT NULL,
    `event` VARCHAR(100) NOT NULL,
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_notif_prefs` (`user_id`, `channel`, `event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AUDIT & SECURITY
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NULL,
    `user_id` BIGINT UNSIGNED NULL,
    `event` ENUM('created','updated','deleted','restored') NOT NULL,
    `auditable_type` VARCHAR(255) NOT NULL,
    `auditable_id` BIGINT UNSIGNED NOT NULL,
    `old_values` JSON NULL,
    `new_values` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_audit_logs_tenant` (`tenant_id`),
    KEY `idx_audit_logs_auditable` (`auditable_type`, `auditable_id`),
    KEY `idx_audit_logs_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `activity_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NULL,
    `user_id` BIGINT UNSIGNED NULL,
    `action` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `properties` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_activity_logs_tenant` (`tenant_id`),
    KEY `idx_activity_logs_user` (`user_id`),
    KEY `idx_activity_logs_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `security_events` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NULL,
    `user_id` BIGINT UNSIGNED NULL,
    `event_type` ENUM('failed_login','account_locked','password_changed','2fa_enabled','2fa_disabled','suspicious_activity','ip_blocked') NOT NULL,
    `ip_address` VARCHAR(45) NULL,
    `details` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_security_events_tenant` (`tenant_id`),
    KEY `idx_security_events_type` (`event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- REPORTING
CREATE TABLE `financial_periods` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `status` ENUM('open','closed') NOT NULL DEFAULT 'open',
    `closed_at` TIMESTAMP NULL,
    `closed_by` BIGINT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    KEY `idx_financial_periods_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `scheduled_reports` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `report_type` VARCHAR(100) NOT NULL,
    `frequency` ENUM('daily','weekly','monthly') NOT NULL,
    `format` ENUM('pdf','excel','csv') NOT NULL DEFAULT 'pdf',
    `recipients` JSON NOT NULL,
    `filters` JSON NULL,
    `next_run_at` TIMESTAMP NOT NULL,
    `last_run_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` BIGINT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    KEY `idx_scheduled_reports_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `report_exports` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `report_type` VARCHAR(100) NOT NULL,
    `format` ENUM('pdf','excel','csv') NOT NULL,
    `file_path` VARCHAR(500) NOT NULL,
    `file_size` BIGINT NULL,
    `filters` JSON NULL,
    `generated_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_report_exports_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `report_snapshots` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NULL,
    `snapshot_date` DATE NOT NULL,
    `report_type` VARCHAR(100) NOT NULL,
    `data` JSON NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_report_snapshots_tenant_date` (`tenant_id`, `snapshot_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FINANCE
CREATE TABLE `expense_categories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_expense_categories_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `expenses` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NULL,
    `category_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `description` TEXT NOT NULL,
    `expense_date` DATE NOT NULL,
    `receipt_url` VARCHAR(500) NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_expenses_tenant` (`tenant_id`),
    KEY `idx_expenses_date` (`expense_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `chart_of_accounts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `type` ENUM('asset','liability','equity','revenue','expense') NOT NULL,
    `parent_id` BIGINT UNSIGNED NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_coa_code_tenant` (`code`, `tenant_id`),
    KEY `idx_coa_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `journal_entries` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `entry_number` VARCHAR(50) NOT NULL,
    `entry_date` DATE NOT NULL,
    `description` TEXT NOT NULL,
    `reference_type` VARCHAR(100) NULL,
    `reference_id` BIGINT UNSIGNED NULL,
    `status` ENUM('draft','posted','voided') NOT NULL DEFAULT 'draft',
    `created_by` BIGINT UNSIGNED NULL,
    `posted_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_journal_entries_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `journal_entry_lines` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `journal_entry_id` BIGINT UNSIGNED NOT NULL,
    `account_id` BIGINT UNSIGNED NOT NULL,
    `debit` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `credit` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_journal_lines_entry` (`journal_entry_id`),
    CONSTRAINT `fk_journal_lines_entry` FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cash_flow_entries` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NULL,
    `type` ENUM('inflow','outflow') NOT NULL,
    `category` VARCHAR(100) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `description` TEXT NULL,
    `entry_date` DATE NOT NULL,
    `reference_type` VARCHAR(100) NULL,
    `reference_id` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cash_flow_tenant` (`tenant_id`),
    KEY `idx_cash_flow_date` (`entry_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;