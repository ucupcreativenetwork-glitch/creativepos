<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenant_settings', function (Blueprint $table) {
            $table->json('onboarding_progress')->nullable()->after('setup_completed');
            $table->json('enabled_payment_methods')->nullable()->after('onboarding_progress');
            $table->boolean('feature_reservations')->default(true)->after('enabled_payment_methods');
            $table->boolean('feature_delivery')->default(true)->after('feature_reservations');
            $table->boolean('feature_qr_menu')->default(true)->after('feature_delivery');
        });
    }

    public function down(): void
    {
        Schema::table('tenant_settings', function (Blueprint $table) {
            $table->dropColumn([
                'onboarding_progress',
                'enabled_payment_methods',
                'feature_reservations',
                'feature_delivery',
                'feature_qr_menu',
            ]);
        });
    }
};