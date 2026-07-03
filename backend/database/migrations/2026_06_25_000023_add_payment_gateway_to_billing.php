<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('billing_invoices', function (Blueprint $table): void {
            $table->string('payment_gateway', 20)->nullable()->after('status');
            $table->string('payment_method', 50)->nullable()->after('payment_gateway');
            $table->string('gateway_order_id', 100)->nullable()->after('payment_method');
            $table->enum('payment_status', ['pending', 'processing', 'paid', 'failed', 'expired', 'cancelled'])
                ->nullable()
                ->after('gateway_order_id');
            $table->string('payment_url', 500)->nullable()->after('payment_status');
            $table->json('payment_instructions')->nullable()->after('payment_url');
            $table->timestamp('payment_expires_at')->nullable()->after('payment_instructions');
            $table->json('gateway_metadata')->nullable()->after('payment_expires_at');

            $table->index(['gateway_order_id']);
            $table->index(['payment_status']);
        });

        Schema::table('billing_payments', function (Blueprint $table): void {
            $table->string('payment_gateway', 20)->nullable()->after('payment_method');
            $table->enum('status', ['pending', 'completed', 'failed', 'refunded'])
                ->default('completed')
                ->after('payment_gateway');
            $table->json('gateway_response')->nullable()->after('transaction_ref');
        });

        Schema::table('subscriptions', function (Blueprint $table): void {
            $table->string('xendit_customer_id', 100)->nullable()->after('cancelled_at');
            $table->string('xendit_recurring_id', 100)->nullable()->after('xendit_customer_id');
            $table->boolean('auto_renew')->default(false)->after('xendit_recurring_id');
        });
    }

    public function down(): void
    {
        Schema::table('subscriptions', function (Blueprint $table): void {
            $table->dropColumn(['xendit_customer_id', 'xendit_recurring_id', 'auto_renew']);
        });

        Schema::table('billing_payments', function (Blueprint $table): void {
            $table->dropColumn(['payment_gateway', 'status', 'gateway_response']);
        });

        Schema::table('billing_invoices', function (Blueprint $table): void {
            $table->dropColumn([
                'payment_gateway',
                'payment_method',
                'gateway_order_id',
                'payment_status',
                'payment_url',
                'payment_instructions',
                'payment_expires_at',
                'gateway_metadata',
            ]);
        });
    }
};