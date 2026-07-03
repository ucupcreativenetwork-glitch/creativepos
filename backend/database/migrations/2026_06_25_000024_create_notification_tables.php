<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_templates', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->nullable()->constrained()->cascadeOnDelete();
            $table->string('event', 100);
            $table->enum('channel', ['email', 'whatsapp', 'push', 'in_app']);
            $table->string('subject', 255)->nullable();
            $table->text('body');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['event', 'channel']);
            $table->index(['tenant_id', 'event']);
        });

        Schema::create('notifications', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 100);
            $table->string('title');
            $table->text('body')->nullable();
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'read_at']);
            $table->index(['tenant_id', 'type']);
        });

        Schema::create('user_notification_preferences', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('channel', ['email', 'whatsapp', 'push', 'in_app']);
            $table->string('event', 100);
            $table->boolean('is_enabled')->default(true);
            $table->timestamps();

            $table->unique(['user_id', 'channel', 'event']);
        });

        Schema::create('notification_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('tenant_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('event', 100);
            $table->enum('channel', ['email', 'whatsapp', 'push', 'in_app']);
            $table->string('recipient', 255)->nullable();
            $table->enum('status', ['sent', 'failed', 'skipped'])->default('sent');
            $table->string('dedup_key', 150)->nullable()->index();
            $table->text('message')->nullable();
            $table->json('response')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::table('whatsapp_configs', function (Blueprint $table): void {
            $table->enum('provider', ['fonnte', 'wablas', 'meta'])
                ->default('fonnte')
                ->after('tenant_id');
            $table->string('api_url', 255)->nullable()->after('provider');
        });

        Schema::table('user_devices', function (Blueprint $table): void {
            $table->string('fcm_token', 500)->nullable()->after('fingerprint');
            $table->index(['user_id', 'fcm_token']);
        });
    }

    public function down(): void
    {
        Schema::table('user_devices', function (Blueprint $table): void {
            $table->dropIndex(['user_id', 'fcm_token']);
            $table->dropColumn('fcm_token');
        });

        Schema::table('whatsapp_configs', function (Blueprint $table): void {
            $table->dropColumn(['provider', 'api_url']);
        });

        Schema::dropIfExists('notification_logs');
        Schema::dropIfExists('user_notification_preferences');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('notification_templates');
    }
};