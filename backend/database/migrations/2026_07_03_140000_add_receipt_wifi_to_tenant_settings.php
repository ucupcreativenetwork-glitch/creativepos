<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenant_settings', function (Blueprint $table) {
            $table->string('wifi_ssid', 100)->nullable()->after('feature_qr_menu');
            $table->string('wifi_password', 100)->nullable()->after('wifi_ssid');
            $table->boolean('receipt_show_wifi')->default(false)->after('wifi_password');
        });
    }

    public function down(): void
    {
        Schema::table('tenant_settings', function (Blueprint $table) {
            $table->dropColumn(['wifi_ssid', 'wifi_password', 'receipt_show_wifi']);
        });
    }
};