<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('business_name')->nullable();
            $table->string('business_type')->nullable();
            $table->string('logo_url', 500)->nullable();
            $table->string('primary_color', 7)->default('#2563EB');
            $table->decimal('service_charge_rate', 5, 2)->default(0);
            $table->decimal('tax_rate', 5, 2)->default(11);
            $table->string('timezone', 50)->default('Asia/Jakarta');
            $table->string('currency', 3)->default('IDR');
            $table->boolean('setup_completed')->default(false);
            $table->timestamps();
            $table->unique('tenant_id');
        });

        Schema::create('outlets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid')->unique();
            $table->string('name');
            $table->string('code', 20);
            $table->text('address')->nullable();
            $table->string('phone', 20)->nullable();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_default')->default(false);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['code', 'tenant_id']);
            $table->index('tenant_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('outlets');
        Schema::dropIfExists('tenant_settings');
    }
};