<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('raw_materials', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->enum('unit', ['gram', 'ml', 'pcs', 'liter'])->default('gram');
            $table->decimal('current_stock', 12, 3)->default(0);
            $table->decimal('min_stock', 12, 3)->default(0);
            $table->decimal('cost_per_unit', 15, 4)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->index(['tenant_id', 'is_active']);
            $table->index(['tenant_id', 'name']);
        });

        Schema::create('product_recipes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('raw_material_id')->constrained()->cascadeOnDelete();
            $table->decimal('quantity_needed', 12, 3);
            $table->enum('unit', ['gram', 'ml', 'pcs', 'liter'])->default('gram');
            $table->string('notes')->nullable();
            $table->timestamps();
            $table->unique(['product_id', 'raw_material_id']);
            $table->index(['tenant_id', 'product_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_recipes');
        Schema::dropIfExists('raw_materials');
    }
};