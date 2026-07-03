<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sale_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid')->unique();
            $table->string('transaction_number', 50);
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cashier_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('member_id')->nullable();
            $table->enum('order_type', ['dine_in', 'takeaway', 'delivery', 'quick_sale'])->default('quick_sale');
            $table->enum('status', ['pending', 'completed', 'voided', 'refunded', 'partial_refund'])->default('completed');
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->decimal('discount_total', 15, 2)->default(0);
            $table->decimal('tax_total', 15, 2)->default(0);
            $table->decimal('service_charge', 15, 2)->default(0);
            $table->decimal('grand_total', 15, 2)->default(0);
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
            $table->unique(['transaction_number', 'tenant_id']);
            $table->index(['tenant_id', 'outlet_id', 'created_at']);
            $table->index(['tenant_id', 'status', 'created_at']);
        });

        Schema::create('sale_transaction_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('transaction_id')->constrained('sale_transactions')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('product_name');
            $table->string('sku', 100);
            $table->decimal('quantity', 10, 3);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('subtotal', 15, 2);
            $table->index('transaction_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sale_transaction_items');
        Schema::dropIfExists('sale_transactions');
    }
};