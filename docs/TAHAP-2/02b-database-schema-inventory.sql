-- ============================================================================
-- CreativePOS — Inventory Domain (29 tables)
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `categories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `slug` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `image_url` VARCHAR(500) NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_categories_uuid` (`uuid`),
    UNIQUE KEY `uk_categories_slug_tenant` (`slug`, `tenant_id`),
    KEY `idx_categories_tenant` (`tenant_id`),
    CONSTRAINT `fk_categories_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sub_categories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `category_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `slug` VARCHAR(255) NOT NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sub_categories_uuid` (`uuid`),
    KEY `idx_sub_categories_tenant` (`tenant_id`),
    KEY `idx_sub_categories_category` (`category_id`),
    CONSTRAINT `fk_sub_categories_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_categories_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `brands` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `logo_url` VARCHAR(500) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_brands_tenant` (`tenant_id`),
    CONSTRAINT `fk_brands_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `products` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `category_id` BIGINT UNSIGNED NULL,
    `sub_category_id` BIGINT UNSIGNED NULL,
    `brand_id` BIGINT UNSIGNED NULL,
    `unit_id` BIGINT UNSIGNED NULL,
    `sku` VARCHAR(100) NOT NULL,
    `barcode` VARCHAR(100) NULL,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `type` ENUM('simple','variant','bundle','service') NOT NULL DEFAULT 'simple',
    `base_price` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `cost_price` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `min_stock` INT NOT NULL DEFAULT 0,
    `max_stock` INT NULL,
    `track_stock` TINYINT(1) NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `is_available` TINYINT(1) NOT NULL DEFAULT 1,
    `show_in_menu` TINYINT(1) NOT NULL DEFAULT 1,
    `show_in_pos` TINYINT(1) NOT NULL DEFAULT 1,
    `preparation_time` INT NULL COMMENT 'minutes',
    `sort_order` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_products_uuid` (`uuid`),
    UNIQUE KEY `uk_products_sku_tenant` (`sku`, `tenant_id`),
    KEY `idx_products_tenant` (`tenant_id`),
    KEY `idx_products_barcode` (`barcode`),
    KEY `idx_products_category` (`category_id`),
    CONSTRAINT `fk_products_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_variants` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `sku` VARCHAR(100) NOT NULL,
    `barcode` VARCHAR(100) NULL,
    `name` VARCHAR(255) NOT NULL,
    `attributes` JSON NULL,
    `price` DECIMAL(15,2) NOT NULL,
    `cost_price` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_variants_sku_tenant` (`sku`, `tenant_id`),
    KEY `idx_product_variants_product` (`product_id`),
    KEY `idx_product_variants_tenant` (`tenant_id`),
    CONSTRAINT `fk_product_variants_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_images` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `url` VARCHAR(500) NOT NULL,
    `alt_text` VARCHAR(255) NULL,
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
    `sort_order` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_product_images_product` (`product_id`),
    CONSTRAINT `fk_product_images_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_bundles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `bundle_price` DECIMAL(15,2) NOT NULL,
    `discount_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_product_bundles_product` (`product_id`),
    CONSTRAINT `fk_product_bundles_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `bundle_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bundle_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `quantity` DECIMAL(10,3) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_bundle_items_bundle` (`bundle_id`),
    CONSTRAINT `fk_bundle_items_bundle` FOREIGN KEY (`bundle_id`) REFERENCES `product_bundles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bundle_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_prices` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `outlet_id` BIGINT UNSIGNED NULL,
    `price` DECIMAL(15,2) NOT NULL,
    `effective_from` DATE NULL,
    `effective_to` DATE NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_product_prices_product` (`product_id`),
    KEY `idx_product_prices_outlet` (`outlet_id`),
    KEY `idx_product_prices_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `modifier_groups` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `min_selection` INT NOT NULL DEFAULT 0,
    `max_selection` INT NOT NULL DEFAULT 1,
    `is_required` TINYINT(1) NOT NULL DEFAULT 0,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_modifier_groups_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `modifiers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `group_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `price` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `sort_order` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_modifiers_group` (`group_id`),
    CONSTRAINT `fk_modifiers_group` FOREIGN KEY (`group_id`) REFERENCES `modifier_groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_modifiers` (
    `product_id` BIGINT UNSIGNED NOT NULL,
    `modifier_group_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`product_id`, `modifier_group_id`),
    CONSTRAINT `fk_product_modifiers_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_product_modifiers_group` FOREIGN KEY (`modifier_group_id`) REFERENCES `modifier_groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `warehouses` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `outlet_id` BIGINT UNSIGNED NULL,
    `name` VARCHAR(255) NOT NULL,
    `code` VARCHAR(20) NOT NULL,
    `address` TEXT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_warehouses_code_tenant` (`code`, `tenant_id`),
    KEY `idx_warehouses_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_stocks` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `quantity` DECIMAL(12,3) NOT NULL DEFAULT 0,
    `reserved_quantity` DECIMAL(12,3) NOT NULL DEFAULT 0,
    `average_cost` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_stocks` (`product_id`, `variant_id`, `warehouse_id`),
    KEY `idx_product_stocks_tenant` (`tenant_id`),
    KEY `idx_product_stocks_warehouse` (`warehouse_id`),
    CONSTRAINT `fk_product_stocks_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
    CONSTRAINT `fk_product_stocks_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_movements` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `type` ENUM('in','out','transfer_in','transfer_out','adjustment','sale','return','opname') NOT NULL,
    `quantity` DECIMAL(12,3) NOT NULL,
    `before_quantity` DECIMAL(12,3) NOT NULL,
    `after_quantity` DECIMAL(12,3) NOT NULL,
    `reference_type` VARCHAR(100) NULL,
    `reference_id` BIGINT UNSIGNED NULL,
    `notes` TEXT NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_stock_movements_tenant` (`tenant_id`),
    KEY `idx_stock_movements_product` (`product_id`),
    KEY `idx_stock_movements_reference` (`reference_type`, `reference_id`),
    KEY `idx_stock_movements_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_transfers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `transfer_number` VARCHAR(50) NOT NULL,
    `from_warehouse_id` BIGINT UNSIGNED NOT NULL,
    `to_warehouse_id` BIGINT UNSIGNED NOT NULL,
    `status` ENUM('draft','in_transit','completed','cancelled') NOT NULL DEFAULT 'draft',
    `notes` TEXT NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `completed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_stock_transfers_number` (`transfer_number`, `tenant_id`),
    KEY `idx_stock_transfers_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_transfer_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `transfer_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `quantity` DECIMAL(12,3) NOT NULL,
    `received_quantity` DECIMAL(12,3) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_stock_transfer_items_transfer` (`transfer_id`),
    CONSTRAINT `fk_stock_transfer_items_transfer` FOREIGN KEY (`transfer_id`) REFERENCES `stock_transfers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_adjustments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `adjustment_number` VARCHAR(50) NOT NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `status` ENUM('draft','approved','cancelled') NOT NULL DEFAULT 'draft',
    `approved_by` BIGINT UNSIGNED NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_stock_adjustments_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_adjustment_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `adjustment_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `before_quantity` DECIMAL(12,3) NOT NULL,
    `after_quantity` DECIMAL(12,3) NOT NULL,
    `difference` DECIMAL(12,3) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_stock_adjustment_items_adjustment` (`adjustment_id`),
    CONSTRAINT `fk_stock_adjustment_items_adjustment` FOREIGN KEY (`adjustment_id`) REFERENCES `stock_adjustments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_opnames` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `opname_number` VARCHAR(50) NOT NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `status` ENUM('in_progress','completed','cancelled') NOT NULL DEFAULT 'in_progress',
    `started_at` TIMESTAMP NOT NULL,
    `completed_at` TIMESTAMP NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `approved_by` BIGINT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    KEY `idx_stock_opnames_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_opname_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `opname_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `system_quantity` DECIMAL(12,3) NOT NULL,
    `actual_quantity` DECIMAL(12,3) NOT NULL,
    `variance` DECIMAL(12,3) NOT NULL,
    `notes` TEXT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_stock_opname_items_opname` (`opname_id`),
    CONSTRAINT `fk_stock_opname_items_opname` FOREIGN KEY (`opname_id`) REFERENCES `stock_opnames` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `inventory_batches` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `batch_number` VARCHAR(100) NOT NULL,
    `quantity` DECIMAL(12,3) NOT NULL,
    `expiry_date` DATE NULL,
    `received_at` TIMESTAMP NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_inventory_batches_product` (`product_id`),
    KEY `idx_inventory_batches_expiry` (`expiry_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `suppliers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `contact_person` VARCHAR(255) NULL,
    `phone` VARCHAR(20) NULL,
    `email` VARCHAR(255) NULL,
    `address` TEXT NULL,
    `payment_terms` VARCHAR(100) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_suppliers_code_tenant` (`code`, `tenant_id`),
    KEY `idx_suppliers_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `purchase_orders` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `po_number` VARCHAR(50) NOT NULL,
    `supplier_id` BIGINT UNSIGNED NOT NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `status` ENUM('draft','pending_approval','approved','ordered','partial','received','cancelled') NOT NULL DEFAULT 'draft',
    `subtotal` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `tax_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `total_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `expected_date` DATE NULL,
    `notes` TEXT NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `approved_by` BIGINT UNSIGNED NULL,
    `approved_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_purchase_orders_number` (`po_number`, `tenant_id`),
    KEY `idx_purchase_orders_tenant` (`tenant_id`),
    KEY `idx_purchase_orders_supplier` (`supplier_id`),
    CONSTRAINT `fk_purchase_orders_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `purchase_order_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `purchase_order_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `quantity` DECIMAL(12,3) NOT NULL,
    `received_quantity` DECIMAL(12,3) NOT NULL DEFAULT 0,
    `unit_price` DECIMAL(15,2) NOT NULL,
    `total_price` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_po_items_po` (`purchase_order_id`),
    CONSTRAINT `fk_po_items_po` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `goods_receipts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `grn_number` VARCHAR(50) NOT NULL,
    `purchase_order_id` BIGINT UNSIGNED NOT NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `received_date` DATE NOT NULL,
    `notes` TEXT NULL,
    `received_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_goods_receipts_number` (`grn_number`, `tenant_id`),
    KEY `idx_goods_receipts_po` (`purchase_order_id`),
    CONSTRAINT `fk_goods_receipts_po` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `goods_receipt_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `goods_receipt_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `quantity` DECIMAL(12,3) NOT NULL,
    `unit_price` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_grn_items_grn` (`goods_receipt_id`),
    CONSTRAINT `fk_grn_items_grn` FOREIGN KEY (`goods_receipt_id`) REFERENCES `goods_receipts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `purchase_returns` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `uuid` CHAR(36) NOT NULL,
    `return_number` VARCHAR(50) NOT NULL,
    `purchase_order_id` BIGINT UNSIGNED NULL,
    `supplier_id` BIGINT UNSIGNED NOT NULL,
    `status` ENUM('draft','approved','completed','cancelled') NOT NULL DEFAULT 'draft',
    `reason` TEXT NULL,
    `total_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
    `created_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_purchase_returns_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `purchase_return_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `purchase_return_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NULL,
    `quantity` DECIMAL(12,3) NOT NULL,
    `unit_price` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_pr_items_return` (`purchase_return_id`),
    CONSTRAINT `fk_pr_items_return` FOREIGN KEY (`purchase_return_id`) REFERENCES `purchase_returns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;