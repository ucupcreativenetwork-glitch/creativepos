<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_modifier_groups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->boolean('is_required')->default(false);
            $table->unsignedTinyInteger('min_select')->default(0);
            $table->unsignedTinyInteger('max_select')->default(1);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->index(['tenant_id', 'product_id']);
        });

        Schema::create('product_modifiers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('group_id')->constrained('product_modifier_groups')->cascadeOnDelete();
            $table->string('name');
            $table->decimal('price_adjustment', 15, 2)->default(0);
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->index(['tenant_id', 'group_id']);
        });

        Schema::table('sale_transaction_items', function (Blueprint $table) {
            $table->json('modifiers')->nullable()->after('unit_price');
            $table->decimal('modifier_price_adjustment', 15, 2)->default(0)->after('modifiers');
        });
    }

    public function down(): void
    {
        Schema::table('sale_transaction_items', function (Blueprint $table) {
            $table->dropColumn(['modifiers', 'modifier_price_adjustment']);
        });

        Schema::dropIfExists('product_modifiers');
        Schema::dropIfExists('product_modifier_groups');
    }
};