<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete();
            $table->foreignId('package_id')->constrained('packages');
            $table->enum('status', ['active', 'past_due', 'suspended', 'cancelled', 'expired'])->default('active')->index();
            $table->enum('billing_cycle', ['monthly', 'yearly'])->default('monthly');
            $table->date('starts_at');
            $table->date('ends_at');
            $table->date('next_billing_date')->nullable()->index();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();

            $table->index('tenant_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};