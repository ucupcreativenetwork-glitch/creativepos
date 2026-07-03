<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::getConnection()->getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE report_exports MODIFY COLUMN status ENUM('pending', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'pending'");
            DB::statement("ALTER TABLE report_exports MODIFY COLUMN format ENUM('csv', 'json', 'xlsx', 'pdf') NOT NULL DEFAULT 'xlsx'");
        }

        Schema::table('report_exports', function (Blueprint $table): void {
            if (! Schema::hasColumn('report_exports', 'error_message')) {
                $table->text('error_message')->nullable()->after('status');
            }
            if (! Schema::hasColumn('report_exports', 'generated_at')) {
                $table->timestamp('generated_at')->nullable()->after('file_path');
            }
        });
    }

    public function down(): void
    {
        Schema::table('report_exports', function (Blueprint $table): void {
            if (Schema::hasColumn('report_exports', 'error_message')) {
                $table->dropColumn('error_message');
            }
            if (Schema::hasColumn('report_exports', 'generated_at')) {
                $table->dropColumn('generated_at');
            }
        });

        if (Schema::getConnection()->getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE report_exports MODIFY COLUMN status ENUM('pending', 'completed', 'failed') NOT NULL DEFAULT 'pending'");
            DB::statement("ALTER TABLE report_exports MODIFY COLUMN format ENUM('csv', 'json') NOT NULL DEFAULT 'csv'");
        }
    }
};