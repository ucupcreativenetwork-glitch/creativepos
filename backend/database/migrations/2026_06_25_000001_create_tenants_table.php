<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenants', function (Blueprint $table): void {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->string('name');
            $table->string('slug', 100)->unique();
            $table->string('email')->unique();
            $table->string('phone', 20)->nullable();
            $table->string('logo_url', 500)->nullable();
            $table->text('address')->nullable();
            $table->string('npwp', 30)->nullable();
            $table->enum('status', ['active', 'suspended', 'trial', 'terminated'])->default('trial')->index();
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('suspended_at')->nullable();
            $table->timestamp('terminated_at')->nullable();
            $table->string('timezone', 50)->default('Asia/Jakarta');
            $table->string('currency', 3)->default('IDR');
            $table->string('locale', 10)->default('id');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenants');
    }
};