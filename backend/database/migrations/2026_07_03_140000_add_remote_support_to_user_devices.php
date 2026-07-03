<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_devices', function (Blueprint $table): void {
            $table->foreignId('tenant_id')->nullable()->after('user_id')->constrained('tenants')->nullOnDelete();
            $table->string('install_id', 64)->nullable()->after('fingerprint');
            $table->string('app_version', 30)->nullable()->after('browser');
            $table->unsignedInteger('build_number')->nullable()->after('app_version');
            $table->string('os_version', 50)->nullable()->after('build_number');
            $table->string('device_model', 120)->nullable()->after('os_version');
            $table->string('mac_address', 64)->nullable()->after('device_model');
            $table->string('last_ip', 45)->nullable()->after('mac_address');
            $table->string('api_base_url', 255)->nullable()->after('last_ip');
            $table->string('agent_version', 20)->nullable()->after('api_base_url');
            $table->timestamp('last_seen_at')->nullable()->after('last_used_at');
            $table->boolean('remote_agent_enabled')->default(true)->after('is_trusted');

            $table->index(['tenant_id', 'last_seen_at']);
            $table->index('install_id');
        });

        Schema::create('device_remote_commands', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_device_id')->constrained('user_devices')->cascadeOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('command', 50);
            $table->json('payload')->nullable();
            $table->string('status', 20)->default('pending');
            $table->longText('result')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->index(['user_device_id', 'status']);
        });

        Schema::create('device_diagnostics', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_device_id')->constrained('user_devices')->cascadeOnDelete();
            $table->string('type', 30);
            $table->string('title', 150)->nullable();
            $table->longText('content');
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['user_device_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_diagnostics');
        Schema::dropIfExists('device_remote_commands');

        Schema::table('user_devices', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('tenant_id');
            $table->dropColumn([
                'install_id',
                'app_version',
                'build_number',
                'os_version',
                'device_model',
                'mac_address',
                'last_ip',
                'api_base_url',
                'agent_version',
                'last_seen_at',
                'remote_agent_enabled',
            ]);
        });
    }
};