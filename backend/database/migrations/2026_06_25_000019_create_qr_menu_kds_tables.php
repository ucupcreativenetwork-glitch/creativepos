<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('outlets', function (Blueprint $table) {
            $table->string('slug', 50)->nullable()->after('code');
        });

        Schema::create('table_areas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->string('name', 100);
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
        });

        Schema::create('tables', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('area_id')->nullable()->constrained('table_areas')->nullOnDelete();
            $table->string('table_number', 20);
            $table->string('name', 100)->nullable();
            $table->unsignedInteger('capacity')->default(4);
            $table->enum('status', ['available', 'occupied', 'reserved', 'cleaning'])->default('available');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['table_number', 'outlet_id']);
        });

        Schema::create('table_qr_codes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('table_id')->constrained()->cascadeOnDelete();
            $table->string('qr_token', 64)->unique();
            $table->boolean('is_active')->default(true);
            $table->timestamp('created_at')->useCurrent();
            $table->unique('table_id');
        });

        Schema::create('digital_menu_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->nullable()->constrained()->nullOnDelete();
            $table->string('theme_color', 7)->default('#2563EB');
            $table->string('welcome_message', 500)->nullable();
            $table->boolean('show_prices')->default(true);
            $table->boolean('allow_guest_order')->default(true);
            $table->unique(['tenant_id', 'outlet_id']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('table_id')->nullable()->after('outlet_id')->constrained()->nullOnDelete();
            $table->unsignedBigInteger('member_id')->nullable()->after('table_id');
            $table->enum('source', ['pos', 'qr_menu', 'delivery', 'reservation'])->default('pos')->after('member_id');
            $table->enum('order_type', ['dine_in', 'takeaway', 'delivery'])->default('dine_in')->after('source');
            $table->text('notes')->nullable()->after('subtotal');
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('product_name');
            $table->decimal('quantity', 10, 3);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('subtotal', 15, 2);
            $table->text('notes')->nullable();
            $table->enum('status', ['pending', 'cooking', 'ready', 'served', 'cancelled'])->default('pending');
            $table->index('order_id');
        });

        Schema::create('order_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('from_status', 30)->nullable();
            $table->string('to_status', 30);
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_status_histories');
        Schema::dropIfExists('order_items');
        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('table_id');
            $table->dropColumn(['member_id', 'source', 'order_type', 'notes']);
        });
        Schema::dropIfExists('digital_menu_settings');
        Schema::dropIfExists('table_qr_codes');
        Schema::dropIfExists('tables');
        Schema::dropIfExists('table_areas');
        Schema::table('outlets', function (Blueprint $table) {
            $table->dropColumn('slug');
        });
    }
};