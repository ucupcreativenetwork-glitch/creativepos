-- ============================================================================
-- CreativePOS Database Schema
-- MySQL 8.0 | utf8mb4_unicode_ci
-- Total Tables: 156
-- Generated: 2026-06-25
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- DOMAIN: PLATFORM & SAAS BILLING (8 tables)
-- ============================================================================

CREATE TABLE `tenants` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid`              CHAR(36) NOT NULL,
    `name`              VARCHAR(255) NOT NULL,
    `slug`              VARCHAR(100) NOT NULL,
    `email`             VARCHAR(255) NOT NULL,
    `phone`             VARCHAR(20) NULL,
    `logo_url`          VARCHAR(500) NULL,
    `address`           TEXT NULL,
    `npwp`              VARCHAR(30) NULL,
    `status`            ENUM('active','suspended','trial','terminated') NOT NULL DEFAULT 'trial',
    `trial_ends_at`     TIMESTAMP NULL,
    `suspended_at`      TIMESTAMP NULL,
    `terminated_at`     TIMESTAMP NULL,
    `timezone`          VARCHAR(50) NOT NULL DEFAULT 'Asia/Jakarta',
    `currency`          VARCHAR(3) NOT NULL DEFAULT 'IDR',
    `locale`            VARCHAR(10) NOT NULL DEFAULT 'id',
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tenants_uuid` (`uuid`),
    UNIQUE KEY `uk_tenants_slug` (`slug`),
    UNIQUE KEY `uk_tenants_email` (`email`),
    KEY `idx_tenants_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `packages` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(100) NOT NULL,
    `slug`              VARCHAR(50) NOT NULL,
    `description`       TEXT NULL,
    `price_monthly`     DECIMAL(15,2) NOT NULL DEFAULT 0,
    `price_yearly`      DECIMAL(15,2) NOT NULL DEFAULT 0,
    `max_outlets`       INT NOT NULL DEFAULT 1,
    `max_users`         INT NOT NULL DEFAULT 5,
    `max_products`      INT NOT NULL DEFAULT 100,
    `max_members`       INT NOT NULL DEFAULT 500,
    `wa_quota_monthly`  INT NOT NULL DEFAULT 0,
    `trial_days`        INT NOT NULL DEFAULT 14,
    `sort_order`        INT NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_packages_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `package_features` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `package_id`        BIGINT UNSIGNED NOT NULL,
    `feature_key`       VARCHAR(100) NOT NULL,
    `feature_value`     VARCHAR(255) NULL,
    `is_enabled`        TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_package_features` (`package_id`, `feature_key`),
    CONSTRAINT `fk_package_features_package` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `subscriptions` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `package_id`        BIGINT UNSIGNED NOT NULL,
    `status`            ENUM('active','past_due','suspended','cancelled','expired') NOT NULL DEFAULT 'active',
    `billing_cycle`     ENUM('monthly','yearly') NOT NULL DEFAULT 'monthly',
    `starts_at`         DATE NOT NULL,
    `ends_at`           DATE NOT NULL,
    `next_billing_date` DATE NULL,
    `cancelled_at`      TIMESTAMP NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_subscriptions_tenant` (`tenant_id`),
    KEY `idx_subscriptions_status` (`status`),
    KEY `idx_subscriptions_next_billing` (`next_billing_date`),
    CONSTRAINT `fk_subscriptions_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subscriptions_package` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `subscription_histories` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `subscription_id`   BIGINT UNSIGNED NOT NULL,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `action`            ENUM('created','renewed','upgraded','downgraded','suspended','cancelled','reactivated') NOT NULL,
    `from_package_id`   BIGINT UNSIGNED NULL,
    `to_package_id`     BIGINT UNSIGNED NULL,
    `notes`             TEXT NULL,
    `performed_by`      BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sub_histories_subscription` (`subscription_id`),
    KEY `idx_sub_histories_tenant` (`tenant_id`),
    CONSTRAINT `fk_sub_histories_subscription` FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `billing_invoices` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `subscription_id`   BIGINT UNSIGNED NOT NULL,
    `invoice_number`    VARCHAR(50) NOT NULL,
    `amount`            DECIMAL(15,2) NOT NULL,
    `tax_amount`        DECIMAL(15,2) NOT NULL DEFAULT 0,
    `total_amount`      DECIMAL(15,2) NOT NULL,
    `status`            ENUM('draft','sent','paid','overdue','cancelled') NOT NULL DEFAULT 'draft',
    `due_date`          DATE NOT NULL,
    `paid_at`           TIMESTAMP NULL,
    `period_start`      DATE NOT NULL,
    `period_end`        DATE NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_billing_invoices_number` (`invoice_number`),
    KEY `idx_billing_invoices_tenant` (`tenant_id`),
    KEY `idx_billing_invoices_status` (`status`),
    CONSTRAINT `fk_billing_invoices_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`),
    CONSTRAINT `fk_billing_invoices_subscription` FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `billing_payments` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_id`        BIGINT UNSIGNED NOT NULL,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `amount`            DECIMAL(15,2) NOT NULL,
    `payment_method`    VARCHAR(50) NOT NULL,
    `transaction_ref`   VARCHAR(255) NULL,
    `gateway_response`  JSON NULL,
    `paid_at`           TIMESTAMP NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_billing_payments_invoice` (`invoice_id`),
    KEY `idx_billing_payments_tenant` (`tenant_id`),
    CONSTRAINT `fk_billing_payments_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `billing_invoices` (`id`),
    CONSTRAINT `fk_billing_payments_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `platform_settings` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `key`               VARCHAR(100) NOT NULL,
    `value`             TEXT NULL,
    `type`              ENUM('string','integer','boolean','json') NOT NULL DEFAULT 'string',
    `description`       VARCHAR(255) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_platform_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DOMAIN: REFERENCE DATA (5 tables)
-- ============================================================================

CREATE TABLE `countries` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`              CHAR(2) NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `phone_code`        VARCHAR(10) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_countries_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `provinces` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `country_id`        BIGINT UNSIGNED NOT NULL,
    `code`              VARCHAR(10) NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_provinces_country` (`country_id`),
    CONSTRAINT `fk_provinces_country` FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cities` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `province_id`       BIGINT UNSIGNED NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_cities_province` (`province_id`),
    CONSTRAINT `fk_cities_province` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `units_of_measure` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`              VARCHAR(10) NOT NULL,
    `name`              VARCHAR(50) NOT NULL,
    `description`       VARCHAR(255) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_uom_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payment_methods` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`              VARCHAR(30) NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `type`              ENUM('cash','transfer','qris','debit_card','credit_card','e_wallet','wallet','other') NOT NULL,
    `icon`              VARCHAR(255) NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_payment_methods_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DOMAIN: AUTHENTICATION & RBAC (17 tables)
-- ============================================================================

CREATE TABLE `users` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`             BIGINT UNSIGNED NULL,
    `uuid`                  CHAR(36) NOT NULL,
    `name`                  VARCHAR(255) NOT NULL,
    `email`                 VARCHAR(255) NOT NULL,
    `phone`                 VARCHAR(20) NULL,
    `password`              VARCHAR(255) NOT NULL,
    `avatar_url`            VARCHAR(500) NULL,
    `outlet_id`             BIGINT UNSIGNED NULL,
    `is_super_admin`        TINYINT(1) NOT NULL DEFAULT 0,
    `status`                ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
    `email_verified_at`     TIMESTAMP NULL,
    `two_factor_enabled`    TINYINT(1) NOT NULL DEFAULT 0,
    `two_factor_secret`     TEXT NULL,
    `two_factor_method`     ENUM('totp','whatsapp','email') NULL,
    `last_login_at`         TIMESTAMP NULL,
    `last_login_ip`         VARCHAR(45) NULL,
    `remember_token`        VARCHAR(100) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_users_uuid` (`uuid`),
    UNIQUE KEY `uk_users_email_tenant` (`email`, `tenant_id`),
    KEY `idx_users_tenant` (`tenant_id`),
    KEY `idx_users_outlet` (`outlet_id`),
    KEY `idx_users_status` (`status`),
    CONSTRAINT `fk_users_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `password_reset_tokens` (
    `email`             VARCHAR(255) NOT NULL,
    `token`             VARCHAR(255) NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `email_verification_tokens` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           BIGINT UNSIGNED NOT NULL,
    `token`             VARCHAR(255) NOT NULL,
    `expires_at`        TIMESTAMP NOT NULL,
    `verified_at`       TIMESTAMP NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_email_verify_user` (`user_id`),
    CONSTRAINT `fk_email_verify_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `otp_verifications` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NULL,
    `identifier`        VARCHAR(255) NOT NULL,
    `channel`           ENUM('email','whatsapp','sms') NOT NULL,
    `code_hash`         VARCHAR(255) NOT NULL,
    `purpose`           ENUM('login','register','reset_password','verify_phone','transaction') NOT NULL,
    `attempts`          INT NOT NULL DEFAULT 0,
    `max_attempts`      INT NOT NULL DEFAULT 5,
    `expires_at`        TIMESTAMP NOT NULL,
    `verified_at`       TIMESTAMP NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_otp_identifier` (`identifier`, `channel`),
    KEY `idx_otp_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `login_histories` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           BIGINT UNSIGNED NOT NULL,
    `tenant_id`         BIGINT UNSIGNED NULL,
    `ip_address`        VARCHAR(45) NOT NULL,
    `user_agent`        TEXT NULL,
    `device_fingerprint` VARCHAR(255) NULL,
    `device_name`       VARCHAR(255) NULL,
    `location`          VARCHAR(255) NULL,
    `is_successful`     TINYINT(1) NOT NULL DEFAULT 1,
    `failure_reason`    VARCHAR(255) NULL,
    `logged_in_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `logged_out_at`     TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    KEY `idx_login_histories_user` (`user_id`),
    KEY `idx_login_histories_tenant` (`tenant_id`),
    KEY `idx_login_histories_date` (`logged_in_at`),
    CONSTRAINT `fk_login_histories_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_devices` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           BIGINT UNSIGNED NOT NULL,
    `device_name`       VARCHAR(255) NOT NULL,
    `fingerprint`       VARCHAR(255) NOT NULL,
    `platform`          VARCHAR(50) NULL,
    `browser`           VARCHAR(100) NULL,
    `is_trusted`        TINYINT(1) NOT NULL DEFAULT 0,
    `last_used_at`      TIMESTAMP NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_devices_fingerprint` (`user_id`, `fingerprint`),
    CONSTRAINT `fk_user_devices_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `two_factor_recovery_codes` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           BIGINT UNSIGNED NOT NULL,
    `code_hash`         VARCHAR(255) NOT NULL,
    `used_at`           TIMESTAMP NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_2fa_recovery_user` (`user_id`),
    CONSTRAINT `fk_2fa_recovery_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `personal_access_tokens` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tokenable_type`    VARCHAR(255) NOT NULL,
    `tokenable_id`      BIGINT UNSIGNED NOT NULL,
    `name`              VARCHAR(255) NOT NULL,
    `token`             VARCHAR(64) NOT NULL,
    `abilities`         TEXT NULL,
    `last_used_at`      TIMESTAMP NULL,
    `expires_at`        TIMESTAMP NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_personal_access_tokens_token` (`token`),
    KEY `idx_personal_access_tokens_tokenable` (`tokenable_type`, `tokenable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sessions` (
    `id`                VARCHAR(255) NOT NULL,
    `user_id`           BIGINT UNSIGNED NULL,
    `ip_address`        VARCHAR(45) NULL,
    `user_agent`        TEXT NULL,
    `payload`           LONGTEXT NOT NULL,
    `last_activity`     INT NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sessions_user` (`user_id`),
    KEY `idx_sessions_last_activity` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `impersonation_logs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `super_admin_id`    BIGINT UNSIGNED NOT NULL,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `impersonated_user_id` BIGINT UNSIGNED NOT NULL,
    `started_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ended_at`          TIMESTAMP NULL,
    `ip_address`        VARCHAR(45) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_impersonation_tenant` (`tenant_id`),
    CONSTRAINT `fk_impersonation_super_admin` FOREIGN KEY (`super_admin_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ip_whitelists` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `ip_address`        VARCHAR(45) NOT NULL,
    `description`       VARCHAR(255) NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ip_whitelist_tenant` (`tenant_id`),
    CONSTRAINT `fk_ip_whitelist_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Spatie Permission Tables
CREATE TABLE `permissions` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(255) NOT NULL,
    `guard_name`        VARCHAR(255) NOT NULL DEFAULT 'web',
    `module`            VARCHAR(50) NULL,
    `description`       VARCHAR(255) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_permissions_name_guard` (`name`, `guard_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `roles` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NULL,
    `name`              VARCHAR(255) NOT NULL,
    `guard_name`        VARCHAR(255) NOT NULL DEFAULT 'web',
    `is_system`         TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_roles_name_tenant_guard` (`name`, `tenant_id`, `guard_name`),
    KEY `idx_roles_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `model_has_permissions` (
    `permission_id`     BIGINT UNSIGNED NOT NULL,
    `model_type`        VARCHAR(255) NOT NULL,
    `model_id`          BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`permission_id`, `model_id`, `model_type`),
    KEY `idx_model_has_permissions_model` (`model_id`, `model_type`),
    CONSTRAINT `fk_model_has_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `model_has_roles` (
    `role_id`           BIGINT UNSIGNED NOT NULL,
    `model_type`        VARCHAR(255) NOT NULL,
    `model_id`          BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`role_id`, `model_id`, `model_type`),
    KEY `idx_model_has_roles_model` (`model_id`, `model_type`),
    CONSTRAINT `fk_model_has_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_has_permissions` (
    `permission_id`     BIGINT UNSIGNED NOT NULL,
    `role_id`           BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`permission_id`, `role_id`),
    CONSTRAINT `fk_role_has_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_role_has_permissions_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DOMAIN: TENANT & OUTLET CONFIGURATION (10 tables)
-- ============================================================================

CREATE TABLE `tenant_settings` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`             BIGINT UNSIGNED NOT NULL,
    `business_name`         VARCHAR(255) NULL,
    `business_type`         ENUM('restaurant','cafe','coffee_shop','retail','minimarket','toko','umkm','franchise','other') NULL,
    `logo_url`              VARCHAR(500) NULL,
    `favicon_url`           VARCHAR(500) NULL,
    `primary_color`         VARCHAR(7) NULL DEFAULT '#2563EB',
    `secondary_color`       VARCHAR(7) NULL,
    `address`               TEXT NULL,
    `city_id`               BIGINT UNSIGNED NULL,
    `postal_code`           VARCHAR(10) NULL,
    `npwp`                  VARCHAR(30) NULL,
    `service_charge_rate`   DECIMAL(5,2) NOT NULL DEFAULT 0,
    `tax_rate`              DECIMAL(5,2) NOT NULL DEFAULT 11.00,
    `timezone`              VARCHAR(50) NOT NULL DEFAULT 'Asia/Jakarta',
    `currency`              VARCHAR(3) NOT NULL DEFAULT 'IDR',
    `date_format`           VARCHAR(20) NOT NULL DEFAULT 'd/m/Y',
    `receipt_footer`        TEXT NULL,
    `setup_completed`       TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tenant_settings_tenant` (`tenant_id`),
    CONSTRAINT `fk_tenant_settings_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tenant_domains` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `domain`            VARCHAR(255) NOT NULL,
    `is_primary`        TINYINT(1) NOT NULL DEFAULT 0,
    `ssl_enabled`       TINYINT(1) NOT NULL DEFAULT 0,
    `verified_at`       TIMESTAMP NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tenant_domains_domain` (`domain`),
    KEY `idx_tenant_domains_tenant` (`tenant_id`),
    CONSTRAINT `fk_tenant_domains_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `outlets` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `uuid`              CHAR(36) NOT NULL,
    `name`              VARCHAR(255) NOT NULL,
    `code`              VARCHAR(20) NOT NULL,
    `address`           TEXT NULL,
    `city_id`           BIGINT UNSIGNED NULL,
    `phone`             VARCHAR(20) NULL,
    `email`             VARCHAR(255) NULL,
    `latitude`          DECIMAL(10,8) NULL,
    `longitude`         DECIMAL(11,8) NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `is_default`        TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_outlets_uuid` (`uuid`),
    UNIQUE KEY `uk_outlets_code_tenant` (`code`, `tenant_id`),
    KEY `idx_outlets_tenant` (`tenant_id`),
    CONSTRAINT `fk_outlets_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `outlet_settings` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `outlet_id`         BIGINT UNSIGNED NOT NULL,
    `service_charge_rate` DECIMAL(5,2) NULL,
    `tax_rate`          DECIMAL(5,2) NULL,
    `allow_dine_in`     TINYINT(1) NOT NULL DEFAULT 1,
    `allow_takeaway`    TINYINT(1) NOT NULL DEFAULT 1,
    `allow_delivery`    TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_outlet_settings_outlet` (`outlet_id`),
    KEY `idx_outlet_settings_tenant` (`tenant_id`),
    CONSTRAINT `fk_outlet_settings_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `business_hours` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `outlet_id`         BIGINT UNSIGNED NOT NULL,
    `day_of_week`       TINYINT NOT NULL COMMENT '0=Sunday, 6=Saturday',
    `open_time`         TIME NOT NULL,
    `close_time`        TIME NOT NULL,
    `is_closed`         TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_business_hours` (`outlet_id`, `day_of_week`),
    KEY `idx_business_hours_tenant` (`tenant_id`),
    CONSTRAINT `fk_business_hours_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tax_configs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `outlet_id`         BIGINT UNSIGNED NULL,
    `name`              VARCHAR(100) NOT NULL,
    `rate`              DECIMAL(5,2) NOT NULL,
    `is_inclusive`      TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_tax_configs_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payment_method_configs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `outlet_id`         BIGINT UNSIGNED NULL,
    `payment_method_id` BIGINT UNSIGNED NOT NULL,
    `is_enabled`        TINYINT(1) NOT NULL DEFAULT 1,
    `config`            JSON NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_payment_method_configs` (`tenant_id`, `outlet_id`, `payment_method_id`),
    CONSTRAINT `fk_pmc_payment_method` FOREIGN KEY (`payment_method_id`) REFERENCES `payment_methods` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `printer_configs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `outlet_id`         BIGINT UNSIGNED NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `type`              ENUM('receipt','kitchen','label') NOT NULL DEFAULT 'receipt',
    `paper_width`       ENUM('58mm','80mm') NOT NULL DEFAULT '58mm',
    `connection_type`   ENUM('usb','network','bluetooth') NOT NULL DEFAULT 'network',
    `ip_address`        VARCHAR(45) NULL,
    `port`              INT NULL,
    `is_default`        TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_printer_configs_tenant` (`tenant_id`),
    KEY `idx_printer_configs_outlet` (`outlet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `receipt_templates` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `outlet_id`         BIGINT UNSIGNED NULL,
    `name`              VARCHAR(100) NOT NULL,
    `header_text`       TEXT NULL,
    `footer_text`       TEXT NULL,
    `show_logo`         TINYINT(1) NOT NULL DEFAULT 1,
    `show_tax_breakdown` TINYINT(1) NOT NULL DEFAULT 1,
    `template_json`     JSON NULL,
    `is_default`        TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_receipt_templates_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `integration_settings` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id`         BIGINT UNSIGNED NOT NULL,
    `provider`          ENUM('midtrans','xendit','whatsapp','google_maps','osm','mailgun','ses') NOT NULL,
    `config`            JSON NOT NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_integration_settings` (`tenant_id`, `provider`),
    CONSTRAINT `fk_integration_settings_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add FK for users.outlet_id after outlets table exists
ALTER TABLE `users` ADD CONSTRAINT `fk_users_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`) ON DELETE SET NULL;

-- ============================================================================
-- DOMAIN: INVENTORY (29 tables) — see 02b-database-schema-inventory.sql
-- DOMAIN: POS (20 tables) — see 02c-database-schema-pos.sql
-- DOMAIN: LOYALTY & WALLET (17 tables) — see 02d-database-schema-loyalty.sql
-- DOMAIN: ORDERS, RESERVATION, DELIVERY (22 tables) — see 02e-database-schema-ops.sql
-- DOMAIN: CRM, WHATSAPP, SYSTEM (31 tables) — see 02f-database-schema-system.sql
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 1;