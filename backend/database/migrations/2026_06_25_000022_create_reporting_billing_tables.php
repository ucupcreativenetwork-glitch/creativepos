<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('billing_invoices', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_id')->nullable()->constrained()->nullOnDelete();
            $table->string('invoice_number', 50);
            $table->decimal('amount', 15, 2);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2);
            $table->enum('status', ['draft', 'sent', 'paid', 'overdue', 'cancelled'])->default('draft')->index();
            $table->date('due_date');
            $table->timestamp('paid_at')->nullable();
            $table->date('period_start')->nullable();
            $table->date('period_end')->nullable();
            $table->timestamps();

            $table->unique(['invoice_number']);
            $table->index(['tenant_id', 'status']);
        });

        Schema::create('billing_payments', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('invoice_id')->constrained('billing_invoices')->cascadeOnDelete();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 15, 2);
            $table->string('payment_method', 50);
            $table->string('transaction_ref', 100)->nullable();
            $table->timestamp('paid_at');
            $table->timestamp('created_at')->useCurrent();

            $table->index(['invoice_id', 'tenant_id']);
        });

        Schema::create('report_exports', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid')->unique();
            $table->string('report_type', 50);
            $table->enum('format', ['csv', 'json'])->default('csv');
            $table->string('file_path', 500)->nullable();
            $table->enum('status', ['pending', 'completed', 'failed'])->default('pending')->index();
            $table->json('filters')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['tenant_id', 'report_type']);
        });

    }

    public function down(): void
    {
        Schema::dropIfExists('report_exports');
        Schema::dropIfExists('billing_payments');
        Schema::dropIfExists('billing_invoices');
    }
};