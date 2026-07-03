<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('held_transactions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cashier_id')->constrained('users')->cascadeOnDelete();
            $table->string('reference_name', 100);
            $table->unsignedBigInteger('table_id')->nullable();
            $table->unsignedBigInteger('member_id')->nullable();
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->timestamp('held_at')->useCurrent();
            $table->timestamps();

            $table->index(['tenant_id', 'outlet_id']);
        });

        Schema::create('held_transaction_items', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('held_transaction_id')->constrained('held_transactions')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('variant_id')->nullable();
            $table->decimal('quantity', 10, 3);
            $table->decimal('unit_price', 15, 2);
            $table->text('notes')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('held_transaction_items');
        Schema::dropIfExists('held_transactions');
    }
};