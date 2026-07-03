<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->nullable()->constrained('tenants')->cascadeOnDelete();
            $table->char('uuid', 36)->unique();
            $table->string('name');
            $table->string('email');
            $table->string('phone', 20)->nullable();
            $table->string('password');
            $table->string('avatar_url', 500)->nullable();
            $table->unsignedBigInteger('outlet_id')->nullable()->index();
            $table->boolean('is_super_admin')->default(false);
            $table->enum('status', ['active', 'inactive', 'suspended'])->default('active')->index();
            $table->timestamp('email_verified_at')->nullable();
            $table->boolean('two_factor_enabled')->default(false);
            $table->text('two_factor_secret')->nullable();
            $table->enum('two_factor_method', ['totp', 'whatsapp', 'email'])->nullable();
            $table->timestamp('last_login_at')->nullable();
            $table->string('last_login_ip', 45)->nullable();
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['email', 'tenant_id']);
            $table->index('tenant_id');
        });

        Schema::create('password_reset_tokens', function (Blueprint $table): void {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};