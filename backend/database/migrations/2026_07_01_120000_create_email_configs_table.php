<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('email_configs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('mailer', 20)->default('smtp');
            $table->string('host', 255)->nullable();
            $table->unsignedSmallInteger('port')->default(587);
            $table->string('encryption', 10)->nullable();
            $table->string('username', 255)->nullable();
            $table->text('password')->nullable();
            $table->string('from_address', 255)->nullable();
            $table->string('from_name', 255)->nullable();
            $table->boolean('is_active')->default(false);
            $table->boolean('send_welcome_email')->default(true);
            $table->timestamps();
            $table->unique('tenant_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('email_configs');
    }
};