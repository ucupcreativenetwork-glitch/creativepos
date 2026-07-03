<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('package_features', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('package_id')->constrained('packages')->cascadeOnDelete();
            $table->string('feature_key', 100);
            $table->string('feature_value', 255)->nullable();
            $table->boolean('is_enabled')->default(true);
            $table->timestamps();

            $table->unique(['package_id', 'feature_key']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('package_features');
    }
};