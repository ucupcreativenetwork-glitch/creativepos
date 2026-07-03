<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_releases', function (Blueprint $table) {
            $table->id();
            $table->string('platform', 20)->default('android');
            $table->string('version', 20);
            $table->unsignedInteger('build_number');
            $table->string('apk_path');
            $table->string('original_filename')->nullable();
            $table->unsignedBigInteger('file_size')->default(0);
            $table->string('checksum_sha256', 64)->nullable();
            $table->text('release_notes')->nullable();
            $table->boolean('is_mandatory')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->unique(['platform', 'build_number']);
            $table->index(['platform', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_releases');
    }
};