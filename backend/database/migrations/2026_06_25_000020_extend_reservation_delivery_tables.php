<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reservations', function (Blueprint $table) {
            $table->unsignedBigInteger('member_id')->nullable()->after('outlet_id');
            $table->foreignId('table_id')->nullable()->after('member_id')->constrained()->nullOnDelete();
            $table->string('customer_email')->nullable()->after('customer_phone');
            $table->text('notes')->nullable()->after('status');
            $table->timestamp('confirmed_at')->nullable()->after('notes');
            $table->timestamp('arrived_at')->nullable()->after('confirmed_at');
            $table->timestamp('cancelled_at')->nullable()->after('arrived_at');
        });

        Schema::create('reservation_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reservation_id')->constrained()->cascadeOnDelete();
            $table->string('from_status', 30)->nullable();
            $table->string('to_status', 30);
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('reservation_time_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('day_of_week');
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedInteger('capacity')->default(10);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->index(['tenant_id', 'outlet_id', 'day_of_week']);
        });

        Schema::create('delivery_zones', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid');
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->string('name', 100);
            $table->string('code', 20)->nullable();
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['code', 'outlet_id']);
        });

        Schema::create('delivery_zone_rates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('delivery_zone_id')->constrained()->cascadeOnDelete();
            $table->decimal('min_distance_km', 8, 2)->default(0);
            $table->decimal('max_distance_km', 8, 2);
            $table->decimal('base_fee', 15, 2)->default(0);
            $table->decimal('fee_per_km', 15, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->index('delivery_zone_id');
        });

        Schema::create('delivery_drivers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid');
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->nullable()->constrained()->nullOnDelete();
            $table->string('vehicle_type', 50)->nullable();
            $table->string('vehicle_plate', 20)->nullable();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_available')->default(true);
            $table->timestamps();
            $table->unique(['user_id', 'tenant_id']);
        });

        Schema::table('delivery_orders', function (Blueprint $table) {
            $table->foreignId('driver_id')->nullable()->after('outlet_id')->constrained('delivery_drivers')->nullOnDelete();
            $table->unsignedBigInteger('member_id')->nullable()->after('driver_id');
            $table->foreignId('delivery_zone_id')->nullable()->after('member_id')->constrained()->nullOnDelete();
            $table->string('delivery_address')->nullable()->after('customer_phone');
            $table->string('delivery_city', 100)->nullable()->after('delivery_address');
            $table->text('delivery_notes')->nullable()->after('delivery_city');
            $table->decimal('subtotal', 15, 2)->default(0)->after('delivery_notes');
            $table->decimal('total_amount', 15, 2)->default(0)->after('shipping_fee');
            $table->decimal('distance_km', 8, 2)->nullable()->after('total_amount');
            $table->unsignedInteger('estimated_minutes')->nullable()->after('distance_km');
            $table->timestamp('assigned_at')->nullable()->after('estimated_minutes');
            $table->timestamp('picked_up_at')->nullable()->after('assigned_at');
            $table->timestamp('delivered_at')->nullable()->after('picked_up_at');
        });

        Schema::create('delivery_order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('delivery_order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('product_name');
            $table->decimal('quantity', 10, 3);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('subtotal', 15, 2);
            $table->text('notes')->nullable();
            $table->index('delivery_order_id');
        });

        Schema::create('delivery_tracking_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->nullable()->constrained('delivery_drivers')->nullOnDelete();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->timestamp('recorded_at')->useCurrent();
            $table->index(['delivery_order_id', 'recorded_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_tracking_points');
        Schema::dropIfExists('delivery_order_items');

        Schema::table('delivery_orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('driver_id');
            $table->dropConstrainedForeignId('delivery_zone_id');
            $table->dropColumn([
                'member_id',
                'delivery_address',
                'delivery_city',
                'delivery_notes',
                'subtotal',
                'total_amount',
                'distance_km',
                'estimated_minutes',
                'assigned_at',
                'picked_up_at',
                'delivered_at',
            ]);
        });

        Schema::dropIfExists('delivery_drivers');
        Schema::dropIfExists('delivery_zone_rates');
        Schema::dropIfExists('delivery_zones');
        Schema::dropIfExists('reservation_time_slots');
        Schema::dropIfExists('reservation_status_histories');

        Schema::table('reservations', function (Blueprint $table) {
            $table->dropConstrainedForeignId('table_id');
            $table->dropColumn([
                'member_id',
                'customer_email',
                'notes',
                'confirmed_at',
                'arrived_at',
                'cancelled_at',
            ]);
        });
    }
};