-- ============================================================================
-- CreativePOS — Loyalty, Wallet, Orders, Reservation, Delivery (39 tables)
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- LOYALTY & MEMBER
CREATE TABLE `tier_configs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `slug` ENUM('bronze','silver','gold','platinum') NOT NULL,
    `min_spend` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `point_multiplier` DECIMAL(3,1) NOT NULL DEFAULT 1.0,
    `benefits` JSON NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tier_configs_slug_tenant` (`slug`, `tenant_id`),
    KEY `idx_tier_configs_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `members` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `member_code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) NULL,
    `phone` VARCHAR(20) NOT NULL,
    `gender` ENUM('male','female','other') NULL,
    `birthday` DATE NULL,
    `tier_id` BIGINT UNSIGNED NULL,
    `qr_code_url` VARCHAR(500) NULL,
    `barcode` VARCHAR(100) NULL,
    `referral_code` VARCHAR(20) NULL,
    `referred_by` BIGINT UNSIGNED NULL,
    `total_spend` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `visit_count` INT NOT NULL DEFAULT 0,
    `last_visit_at` TIMESTAMP NULL,
    `status` ENUM('active','inactive','blocked') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_members_uuid` (`uuid`),
    UNIQUE KEY `uk_members_code_tenant` (`member_code`, `tenant_id`),
    UNIQUE KEY `uk_members_phone_tenant` (`phone`, `tenant_id`),
    KEY `idx_members_tenant` (`tenant_id`),
    KEY `idx_members_tier` (`tier_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `member_addresses` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `address` TEXT NOT NULL,
    `city_id` BIGINT UNSIGNED NULL,
    `postal_code` VARCHAR(10) NULL,
    `latitude` DECIMAL(10,8) NULL,
    `longitude` DECIMAL(11,8) NULL,
    `is_default` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_member_addresses_member` (`member_id`),
    CONSTRAINT `fk_member_addresses_member` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `point_configs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `earn_amount` DECIMAL(15,2) NOT NULL DEFAULT 10000,
    `earn_points` INT NOT NULL DEFAULT 1,
    `redeem_points` INT NOT NULL DEFAULT 100,
    `redeem_value` DECIMAL(15,2) NOT NULL DEFAULT 10000,
    `point_expiry_days` INT NULL,
    `min_redeem_points` INT NOT NULL DEFAULT 100,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_point_configs_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `member_points` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NOT NULL,
    `balance` INT NOT NULL DEFAULT 0,
    `lifetime_earned` INT NOT NULL DEFAULT 0,
    `lifetime_redeemed` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_member_points_member` (`member_id`),
    KEY `idx_member_points_tenant` (`tenant_id`),
    CONSTRAINT `fk_member_points_member` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `point_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NOT NULL,
    `type` ENUM('earn','redeem','expire','adjustment','referral','birthday') NOT NULL,
    `points` INT NOT NULL,
    `balance_after` INT NOT NULL,
    `reference_type` VARCHAR(100) NULL,
    `reference_id` BIGINT UNSIGNED NULL,
    `description` VARCHAR(255) NULL,
    `expires_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_point_transactions_member` (`member_id`),
    KEY `idx_point_transactions_tenant` (`tenant_id`),
    KEY `idx_point_transactions_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rewards` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `type` ENUM('voucher','cashback','product','birthday','referral') NOT NULL,
    `points_required` INT NULL,
    `value` DECIMAL(15,2) NULL,
    `product_id` BIGINT UNSIGNED NULL,
    `tier_id` BIGINT UNSIGNED NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_rewards_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `member_rewards` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NOT NULL,
    `reward_id` BIGINT UNSIGNED NOT NULL,
    `status` ENUM('available','used','expired') NOT NULL DEFAULT 'available',
    `used_at` TIMESTAMP NULL,
    `expires_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_member_rewards_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `referral_codes` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NOT NULL,
    `code` VARCHAR(20) NOT NULL,
    `usage_count` INT NOT NULL DEFAULT 0,
    `max_usage` INT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_referral_codes_code` (`code`),
    KEY `idx_referral_codes_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `referrals` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `referrer_id` BIGINT UNSIGNED NOT NULL,
    `referee_id` BIGINT UNSIGNED NOT NULL,
    `referral_code_id` BIGINT UNSIGNED NOT NULL,
    `referrer_rewarded` TINYINT(1) NOT NULL DEFAULT 0,
    `referee_rewarded` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_referrals_referrer` (`referrer_id`),
    KEY `idx_referrals_referee` (`referee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `birthday_rewards_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NOT NULL,
    `reward_id` BIGINT UNSIGNED NOT NULL,
    `year` INT NOT NULL,
    `sent_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_birthday_rewards` (`member_id`, `year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- WALLET
CREATE TABLE `wallets` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NOT NULL,
    `balance` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `lifetime_topup` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `lifetime_spent` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `status` ENUM('active','frozen','closed') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_wallets_member` (`member_id`),
    KEY `idx_wallets_tenant` (`tenant_id`),
    CONSTRAINT `fk_wallets_member` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `wallet_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `wallet_id` BIGINT UNSIGNED NOT NULL,
    `type` ENUM('topup','withdraw','transfer_in','transfer_out','payment','refund','adjustment') NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `balance_before` DECIMAL(15,2) NOT NULL,
    `balance_after` DECIMAL(15,2) NOT NULL,
    `reference_type` VARCHAR(100) NULL,
    `reference_id` BIGINT UNSIGNED NULL,
    `description` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_wallet_transactions_wallet` (`wallet_id`),
    KEY `idx_wallet_transactions_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `wallet_top_ups` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `wallet_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `method` ENUM('cash','transfer','payment_gateway') NOT NULL,
    `status` ENUM('pending','completed','failed') NOT NULL DEFAULT 'pending',
    `reference_number` VARCHAR(255) NULL,
    `processed_by` BIGINT UNSIGNED NULL,
    `completed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_wallet_topups_wallet` (`wallet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `wallet_withdrawals` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `wallet_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `bank_account` VARCHAR(255) NULL,
    `status` ENUM('pending','approved','rejected','completed') NOT NULL DEFAULT 'pending',
    `approved_by` BIGINT UNSIGNED NULL,
    `completed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_wallet_withdrawals_wallet` (`wallet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `wallet_transfers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `from_wallet_id` BIGINT UNSIGNED NOT NULL,
    `to_wallet_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `notes` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_wallet_transfers_from` (`from_wallet_id`),
    KEY `idx_wallet_transfers_to` (`to_wallet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ORDERS & KDS
CREATE TABLE `orders` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `order_number` VARCHAR(50) NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `table_id` BIGINT UNSIGNED NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `sale_transaction_id` BIGINT UNSIGNED NULL,
    `source` ENUM('pos','qr_menu','delivery','reservation') NOT NULL,
    `order_type` ENUM('dine_in','takeaway','delivery') NOT NULL DEFAULT 'dine_in',
    `status` ENUM('pending','cooking','ready','served','completed','cancelled') NOT NULL DEFAULT 'pending',
    `subtotal` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_orders_uuid` (`uuid`),
    UNIQUE KEY `uk_orders_number` (`order_number`, `tenant_id`),
    KEY `idx_orders_tenant` (`tenant_id`),
    KEY `idx_orders_outlet` (`outlet_id`),
    KEY `idx_orders_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `product_name` VARCHAR(255) NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `unit_price` DECIMAL(15,2) NOT NULL,
    `subtotal` DECIMAL(15,2) NOT NULL,
    `notes` TEXT NULL,
    `status` ENUM('pending','cooking','ready','served','cancelled') NOT NULL DEFAULT 'pending',
    PRIMARY KEY (`id`),
    KEY `idx_order_items_order` (`order_id`),
    CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_item_modifiers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_item_id` BIGINT UNSIGNED NOT NULL,
    `modifier_id` BIGINT UNSIGNED NOT NULL,
    `modifier_name` VARCHAR(255) NOT NULL,
    `price` DECIMAL(15,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_order_item_modifiers_item` (`order_item_id`),
    CONSTRAINT `fk_order_item_modifiers_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_status_histories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `from_status` VARCHAR(30) NULL,
    `to_status` VARCHAR(30) NOT NULL,
    `changed_by` BIGINT UNSIGNED NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_order_status_histories_order` (`order_id`),
    CONSTRAINT `fk_order_status_histories_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kitchen_stations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_kitchen_stations_outlet` (`outlet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kitchen_station_products` (
    `station_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`station_id`, `product_id`),
    CONSTRAINT `fk_ksp_station` FOREIGN KEY (`station_id`) REFERENCES `kitchen_stations` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ksp_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `digital_menu_settings` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NULL,
    `theme_color` VARCHAR(7) NULL,
    `logo_url` VARCHAR(500) NULL,
    `welcome_message` TEXT NULL,
    `show_prices` TINYINT(1) NOT NULL DEFAULT 1,
    `allow_guest_order` TINYINT(1) NOT NULL DEFAULT 1,
    `require_member_login` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_digital_menu_tenant_outlet` (`tenant_id`, `outlet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RESERVATION
CREATE TABLE `reservations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `reservation_number` VARCHAR(50) NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `table_id` BIGINT UNSIGNED NULL,
    `customer_name` VARCHAR(255) NOT NULL,
    `customer_phone` VARCHAR(20) NOT NULL,
    `customer_email` VARCHAR(255) NULL,
    `guest_count` INT NOT NULL,
    `reservation_date` DATE NOT NULL,
    `reservation_time` TIME NOT NULL,
    `status` ENUM('pending','confirmed','arrived','completed','cancelled','no_show') NOT NULL DEFAULT 'pending',
    `notes` TEXT NULL,
    `confirmed_at` TIMESTAMP NULL,
    `arrived_at` TIMESTAMP NULL,
    `cancelled_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_reservations_number` (`reservation_number`, `tenant_id`),
    KEY `idx_reservations_tenant` (`tenant_id`),
    KEY `idx_reservations_date` (`reservation_date`, `reservation_time`),
    KEY `idx_reservations_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `reservation_status_histories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reservation_id` BIGINT UNSIGNED NOT NULL,
    `from_status` VARCHAR(30) NULL,
    `to_status` VARCHAR(30) NOT NULL,
    `changed_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_reservation_status_reservation` (`reservation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `reservation_time_slots` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `day_of_week` TINYINT NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `max_reservations` INT NOT NULL DEFAULT 10,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_reservation_slots_outlet` (`outlet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `reservation_reminders` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reservation_id` BIGINT UNSIGNED NOT NULL,
    `type` ENUM('h_minus_1','h_minus_0') NOT NULL,
    `channel` ENUM('whatsapp','email') NOT NULL,
    `sent_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_reservation_reminders_reservation` (`reservation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- DELIVERY
CREATE TABLE `delivery_zones` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `polygon` JSON NULL,
    `radius_km` DECIMAL(5,2) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_delivery_zones_outlet` (`outlet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_zone_rates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `zone_id` BIGINT UNSIGNED NOT NULL,
    `type` ENUM('flat','per_km') NOT NULL,
    `rate` DECIMAL(15,2) NOT NULL,
    `min_fee` DECIMAL(15,2) NULL,
    `max_fee` DECIMAL(15,2) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_delivery_zone_rates_zone` (`zone_id`),
    CONSTRAINT `fk_delivery_zone_rates_zone` FOREIGN KEY (`zone_id`) REFERENCES `delivery_zones` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_drivers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NULL,
    `name` VARCHAR(255) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `type` ENUM('internal','external') NOT NULL DEFAULT 'internal',
    `vehicle_type` VARCHAR(50) NULL,
    `vehicle_number` VARCHAR(20) NULL,
    `is_available` TINYINT(1) NOT NULL DEFAULT 1,
    `current_latitude` DECIMAL(10,8) NULL,
    `current_longitude` DECIMAL(11,8) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_delivery_drivers_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_addresses` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `member_id` BIGINT UNSIGNED NULL,
    `label` VARCHAR(50) NOT NULL,
    `recipient_name` VARCHAR(255) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `address` TEXT NOT NULL,
    `city_id` BIGINT UNSIGNED NULL,
    `postal_code` VARCHAR(10) NULL,
    `latitude` DECIMAL(10,8) NULL,
    `longitude` DECIMAL(11,8) NULL,
    `notes` TEXT NULL,
    `is_default` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_delivery_addresses_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_orders` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `delivery_number` VARCHAR(50) NOT NULL,
    `outlet_id` BIGINT UNSIGNED NOT NULL,
    `order_id` BIGINT UNSIGNED NULL,
    `sale_transaction_id` BIGINT UNSIGNED NULL,
    `driver_id` BIGINT UNSIGNED NULL,
    `address_id` BIGINT UNSIGNED NOT NULL,
    `customer_name` VARCHAR(255) NOT NULL,
    `customer_phone` VARCHAR(20) NOT NULL,
    `status` ENUM('waiting','processing','cooking','ready','delivering','completed','cancelled') NOT NULL DEFAULT 'waiting',
    `shipping_fee` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `distance_km` DECIMAL(8,2) NULL,
    `estimated_minutes` INT NULL,
    `assigned_at` TIMESTAMP NULL,
    `picked_up_at` TIMESTAMP NULL,
    `delivered_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_delivery_orders_number` (`delivery_number`, `tenant_id`),
    KEY `idx_delivery_orders_tenant` (`tenant_id`),
    KEY `idx_delivery_orders_status` (`status`),
    KEY `idx_delivery_orders_driver` (`driver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_order_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `delivery_order_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `product_name` VARCHAR(255) NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `unit_price` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_delivery_order_items_order` (`delivery_order_id`),
    CONSTRAINT `fk_delivery_order_items_order` FOREIGN KEY (`delivery_order_id`) REFERENCES `delivery_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_tracking_points` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `delivery_order_id` BIGINT UNSIGNED NOT NULL,
    `latitude` DECIMAL(10,8) NOT NULL,
    `longitude` DECIMAL(11,8) NOT NULL,
    `recorded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_delivery_tracking_order` (`delivery_order_id`),
    CONSTRAINT `fk_delivery_tracking_order` FOREIGN KEY (`delivery_order_id`) REFERENCES `delivery_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_proofs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `delivery_order_id` BIGINT UNSIGNED NOT NULL,
    `photo_url` VARCHAR(500) NOT NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_delivery_proofs_order` (`delivery_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `delivery_ratings` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `delivery_order_id` BIGINT UNSIGNED NOT NULL,
    `rating` TINYINT NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
    `comment` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_delivery_ratings_order` (`delivery_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;