<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique();
            $table->string('name', 100);
            $table->enum('type', ['cash', 'transfer', 'qris', 'debit_card', 'credit_card', 'e_wallet', 'wallet', 'other']);
            $table->string('icon', 255)->nullable();
            $table->boolean('is_active')->default(true);
        });

        Schema::create('shifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cashier_id')->constrained('users')->cascadeOnDelete();
            $table->string('shift_number', 50);
            $table->enum('status', ['open', 'closed'])->default('open');
            $table->decimal('opening_cash', 15, 2)->default(0);
            $table->decimal('closing_cash', 15, 2)->nullable();
            $table->decimal('expected_cash', 15, 2)->nullable();
            $table->decimal('cash_difference', 15, 2)->nullable();
            $table->decimal('total_sales', 15, 2)->default(0);
            $table->unsignedInteger('total_transactions')->default(0);
            $table->timestamp('opened_at');
            $table->timestamp('closed_at')->nullable();
            $table->foreignId('closed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->index(['tenant_id', 'outlet_id', 'status']);
            $table->index(['cashier_id', 'status']);
        });

        Schema::create('sale_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('transaction_id')->constrained('sale_transactions')->cascadeOnDelete();
            $table->foreignId('payment_method_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 15, 2);
            $table->string('reference_number', 255)->nullable();
            $table->enum('status', ['pending', 'completed', 'failed', 'refunded'])->default('completed');
            $table->timestamp('paid_at')->useCurrent();
            $table->index(['transaction_id', 'tenant_id']);
        });

        Schema::table('sale_transactions', function (Blueprint $table) {
            $table->foreignId('shift_id')->nullable()->after('cashier_id')->constrained('shifts')->nullOnDelete();
            $table->text('notes')->nullable()->after('grand_total');
        });
    }

    public function down(): void
    {
        Schema::table('sale_transactions', function (Blueprint $table) {
            $table->dropConstrainedForeignId('shift_id');
            $table->dropColumn('notes');
        });

        Schema::dropIfExists('sale_payments');
        Schema::dropIfExists('shifts');
        Schema::dropIfExists('payment_methods');
    }
};