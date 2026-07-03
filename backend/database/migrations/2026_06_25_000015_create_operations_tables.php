<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid')->unique();
            $table->string('order_number', 50);
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->enum('status', ['pending', 'cooking', 'ready', 'served', 'completed', 'cancelled'])->default('pending');
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->timestamps();
            $table->unique(['order_number', 'tenant_id']);
            $table->index(['tenant_id', 'status']);
        });

        Schema::create('reservations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid');
            $table->string('reservation_number', 50);
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->string('customer_name');
            $table->string('customer_phone', 20);
            $table->integer('guest_count');
            $table->date('reservation_date');
            $table->time('reservation_time');
            $table->enum('status', ['pending', 'confirmed', 'arrived', 'completed', 'cancelled', 'no_show'])->default('pending');
            $table->timestamps();
            $table->unique(['reservation_number', 'tenant_id']);
            $table->index(['tenant_id', 'reservation_date', 'status']);
        });

        Schema::create('delivery_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid');
            $table->string('delivery_number', 50);
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->string('customer_name');
            $table->string('customer_phone', 20);
            $table->enum('status', ['waiting', 'processing', 'cooking', 'ready', 'delivering', 'completed', 'cancelled'])->default('waiting');
            $table->decimal('shipping_fee', 15, 2)->default(0);
            $table->timestamps();
            $table->unique(['delivery_number', 'tenant_id']);
            $table->index(['tenant_id', 'status']);
        });

        Schema::create('support_tickets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid');
            $table->string('ticket_number', 50);
            $table->string('subject');
            $table->enum('priority', ['low', 'medium', 'high', 'critical'])->default('medium');
            $table->enum('status', ['open', 'assigned', 'pending', 'resolved', 'closed'])->default('open');
            $table->timestamps();
            $table->unique(['ticket_number', 'tenant_id']);
            $table->index(['tenant_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_tickets');
        Schema::dropIfExists('delivery_orders');
        Schema::dropIfExists('reservations');
        Schema::dropIfExists('orders');
    }
};