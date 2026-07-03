-- ============================================================================
-- CreativePOS — POS Domain (20 tables)
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `table_areas` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_table_areas_tenant` (`tenant_id`),
    KEY `idx_table_areas_outlet` (`outlet_id`),
    CONSTRAINT `fk_table_areas_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tables` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `area_id` BIGINT UNSIGNED NULL,
    `table_number` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NULL,
    `capacity` INT NOT NULL DEFAULT 4,
    `status` ENUM('available','occupied','reserved','cleaning') NOT NULL DEFAULT 'available',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tables_number_outlet` (`table_number`, `outlet_id`),
    KEY `idx_tables_tenant` (`tenant_id`),
    CONSTRAINT `fk_tables_outlet` FOREIGN KEY (`outlet_id`) REFERENCES `outlets` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tables_area` FOREIGN KEY (`area_id`) REFERENCES `table_areas` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `table_qr_codes` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `table_id` BIGINT UNSIGNED NOT NULL,
    `qr_code_url` VARCHAR(500) NOT NULL,
    `qr_token` VARCHAR(100) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_table_qr_token` (`qr_token`),
    UNIQUE KEY `uk_table_qr_table` (`table_id`),
    CONSTRAINT `fk_table_qr_table` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `shifts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `cashier_id` BIGINT UNSIGNED NOT NULL,
    `shift_number` VARCHAR(50) NOT NULL,
    `status` ENUM('open','closed') NOT NULL DEFAULT 'open',
    `opening_cash` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `closing_cash` DECIMAL(15,2) NULL,
    `expected_cash` DECIMAL(15,2) NULL,
    `cash_difference` DECIMAL(15,2) NULL,
    `total_sales` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `total_transactions` INT NOT NULL DEFAULT 0,
    `opened_at` TIMESTAMP NOT NULL,
    `closed_at` TIMESTAMP NULL,
    `closed_by` BIGINT UNSIGNED NULL,
    `notes` TEXT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_shifts_tenant` (`tenant_id`),
    KEY `idx_shifts_outlet` (`outlet_id`),
    KEY `idx_shifts_cashier` (`cashier_id`),
    KEY `idx_shifts_opened` (`opened_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cash_drawer_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `type` ENUM('cash_in','cash_out','sale','refund','adjustment') NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `balance_after` DECIMAL(15,2) NOT NULL,
    `notes` TEXT NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cash_drawer_shift` (`shift_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `discount_types` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `type` ENUM('percentage','nominal','voucher','promo') NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_discount_types_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promos` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `code` VARCHAR(50) NULL,
    `type` ENUM('percentage','nominal','buy_x_get_y','bundle') NOT NULL,
    `value` DECIMAL(15,2) NOT NULL,
    `min_purchase` DECIMAL(15,2) NULL,
    `max_discount` DECIMAL(15,2) NULL,
    `starts_at` TIMESTAMP NOT NULL,
    `ends_at` TIMESTAMP NOT NULL,
    `usage_limit` INT NULL,
    `usage_count` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_promos_tenant` (`tenant_id`),
    KEY `idx_promos_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promo_rules` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `promo_id` BIGINT UNSIGNED NOT NULL,
    `rule_type` ENUM('min_qty','min_amount','day_of_week','time_range','member_tier','outlet') NOT NULL,
    `rule_value` JSON NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_promo_rules_promo` (`promo_id`),
    CONSTRAINT `fk_promo_rules_promo` FOREIGN KEY (`promo_id`) REFERENCES `promos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `promo_products` (
    `promo_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`promo_id`, `product_id`),
    CONSTRAINT `fk_promo_products_promo` FOREIGN KEY (`promo_id`) REFERENCES `promos` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_promo_products_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `vouchers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `type` ENUM('percentage','nominal','free_product') NOT NULL,
    `value` DECIMAL(15,2) NOT NULL,
    `min_purchase` DECIMAL(15,2) NULL,
    `max_uses` INT NULL,
    `used_count` INT NOT NULL DEFAULT 0,
    `starts_at` TIMESTAMP NULL,
    `expires_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_vouchers_code_tenant` (`code`, `tenant_id`),
    KEY `idx_vouchers_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `voucher_usages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `transaction_id` BIGINT UNSIGNED NULL,
    `discount_amount` DECIMAL(15,2) NOT NULL,
    `used_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_voucher_usages_voucher` (`voucher_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sale_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `transaction_number` VARCHAR(50) NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `shift_id` BIGINT UNSIGNED NULL,
    `cashier_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `table_id` BIGINT UNSIGNED NULL,
    `order_id` BIGINT UNSIGNED NULL,
    `order_type` ENUM('dine_in','takeaway','delivery','quick_sale') NOT NULL DEFAULT 'quick_sale',
    `status` ENUM('pending','completed','voided','refunded','partial_refund') NOT NULL DEFAULT 'pending',
    `subtotal` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `discount_total` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `tax_total` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `service_charge` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `grand_total` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `paid_total` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `change_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `points_earned` INT NOT NULL DEFAULT 0,
    `points_redeemed` INT NOT NULL DEFAULT 0,
    `notes` TEXT NULL,
    `completed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sale_transactions_uuid` (`uuid`),
    UNIQUE KEY `uk_sale_transactions_number` (`transaction_number`, `tenant_id`),
    KEY `idx_sale_transactions_tenant` (`tenant_id`),
    KEY `idx_sale_transactions_outlet` (`outlet_id`),
    KEY `idx_sale_transactions_shift` (`shift_id`),
    KEY `idx_sale_transactions_member` (`member_id`),
    KEY `idx_sale_transactions_date` (`created_at`),
    KEY `idx_sale_transactions_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sale_transaction_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `product_name` VARCHAR(255) NOT NULL,
    `sku` VARCHAR(100) NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `unit_price` DECIMAL(15,2) NOT NULL,
    `discount_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `tax_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `subtotal` DECIMAL(15,2) NOT NULL,
    `notes` TEXT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sale_items_transaction` (`transaction_id`),
    KEY `idx_sale_items_product` (`product_id`),
    CONSTRAINT `fk_sale_items_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `sale_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sale_transaction_discounts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `discount_type_id` BIGINT UNSIGNED NULL,
    `promo_id` BIGINT UNSIGNED NULL,
    `voucher_id` BIGINT UNSIGNED NULL,
    `name` VARCHAR(255) NOT NULL,
    `type` ENUM('percentage','nominal') NOT NULL,
    `value` DECIMAL(15,2) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sale_discounts_transaction` (`transaction_id`),
    CONSTRAINT `fk_sale_discounts_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `sale_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sale_transaction_taxes` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `tax_config_id` BIGINT UNSIGNED NULL,
    `name` VARCHAR(100) NOT NULL,
    `rate` DECIMAL(5,2) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sale_taxes_transaction` (`transaction_id`),
    CONSTRAINT `fk_sale_taxes_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `sale_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sale_payments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `payment_method_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `reference_number` VARCHAR(255) NULL,
    `gateway_response` JSON NULL,
    `status` ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'completed',
    `paid_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sale_payments_transaction` (`transaction_id`),
    KEY `idx_sale_payments_tenant` (`tenant_id`),
    CONSTRAINT `fk_sale_payments_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `sale_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `held_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `cashier_id` BIGINT UNSIGNED NOT NULL,
    `reference_name` VARCHAR(100) NOT NULL,
    `table_id` BIGINT UNSIGNED NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `subtotal` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `held_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_held_transactions_tenant` (`tenant_id`),
    KEY `idx_held_transactions_outlet` (`outlet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `held_transaction_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `held_transaction_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `unit_price` DECIMAL(15,2) NOT NULL,
    `notes` TEXT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_held_items_held` (`held_transaction_id`),
    CONSTRAINT `fk_held_items_held` FOREIGN KEY (`held_transaction_id`) REFERENCES `held_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `refunds` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `refund_number` VARCHAR(50) NOT NULL,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `type` ENUM('full','partial') NOT NULL,
    `reason` TEXT NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `status` ENUM('pending','approved','completed','rejected') NOT NULL DEFAULT 'pending',
    `approved_by` BIGINT UNSIGNED NULL,
    `created_by` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_refunds_transaction` (`transaction_id`),
    KEY `idx_refunds_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `refund_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `refund_id` BIGINT UNSIGNED NOT NULL,
    `transaction_item_id` BIGINT UNSIGNED NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_refund_items_refund` (`refund_id`),
    CONSTRAINT `fk_refund_items_refund` FOREIGN KEY (`refund_id`) REFERENCES `refunds` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `void_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `reason` TEXT NOT NULL,
    `voided_by` BIGINT UNSIGNED NOT NULL,
    `approved_by` BIGINT UNSIGNED NULL,
    `voided_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_void_logs_transaction` (`transaction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;