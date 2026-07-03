<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('login_histories', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('tenant_id')->nullable()->index();
            $table->string('ip_address', 45);
            $table->text('user_agent')->nullable();
            $table->string('device_fingerprint', 255)->nullable();
            $table->string('device_name', 255)->nullable();
            $table->string('location', 255)->nullable();
            $table->boolean('is_successful')->default(true);
            $table->string('failure_reason', 255)->nullable();
            $table->timestamp('logged_in_at')->useCurrent()->index();
            $table->timestamp('logged_out_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('login_histories');
    }
};