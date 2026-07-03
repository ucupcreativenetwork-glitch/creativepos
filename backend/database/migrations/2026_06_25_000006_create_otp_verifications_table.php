<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('otp_verifications', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('tenant_id')->nullable()->index();
            $table->string('identifier');
            $table->enum('channel', ['email', 'whatsapp', 'sms']);
            $table->string('code_hash');
            $table->enum('purpose', ['login', 'register', 'reset_password', 'verify_phone', 'transaction']);
            $table->integer('attempts')->default(0);
            $table->integer('max_attempts')->default(5);
            $table->timestamp('expires_at');
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['identifier', 'channel']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('otp_verifications');
    }
};