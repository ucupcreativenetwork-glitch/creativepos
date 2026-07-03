<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tier_configs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name', 50);
            $table->enum('slug', ['bronze', 'silver', 'gold', 'platinum']);
            $table->decimal('min_spend', 15, 2)->default(0);
            $table->decimal('point_multiplier', 3, 1)->default(1);
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->unique(['slug', 'tenant_id']);
        });

        Schema::table('members', function (Blueprint $table) {
            $table->date('birthday')->nullable()->after('phone');
            $table->foreignId('tier_id')->nullable()->after('birthday')->constrained('tier_configs')->nullOnDelete();
            $table->string('qr_token', 64)->nullable()->unique()->after('member_code');
            $table->unsignedInteger('visit_count')->default(0)->after('total_spend');
            $table->timestamp('last_visit_at')->nullable()->after('visit_count');
        });

        Schema::create('point_configs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->decimal('earn_amount', 15, 2)->default(10000);
            $table->unsignedInteger('earn_points')->default(1);
            $table->unsignedInteger('redeem_points')->default(100);
            $table->decimal('redeem_value', 15, 2)->default(10000);
            $table->unsignedInteger('min_redeem_points')->default(100);
            $table->unsignedInteger('point_expiry_days')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unique('tenant_id');
        });

        Schema::create('member_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('balance')->default(0);
            $table->unsignedInteger('lifetime_earned')->default(0);
            $table->unsignedInteger('lifetime_redeemed')->default(0);
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->unique('member_id');
        });

        Schema::create('point_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['earn', 'redeem', 'expire', 'adjustment', 'referral', 'birthday']);
            $table->integer('points');
            $table->unsignedInteger('balance_after');
            $table->string('reference_type', 100)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->string('description', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['member_id', 'created_at']);
        });

        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->decimal('balance', 15, 2)->default(0);
            $table->decimal('lifetime_topup', 15, 2)->default(0);
            $table->decimal('lifetime_spent', 15, 2)->default(0);
            $table->enum('status', ['active', 'frozen', 'closed'])->default('active');
            $table->timestamps();
            $table->unique('member_id');
        });

        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['topup', 'withdraw', 'transfer_in', 'transfer_out', 'payment', 'refund', 'adjustment']);
            $table->decimal('amount', 15, 2);
            $table->decimal('balance_before', 15, 2);
            $table->decimal('balance_after', 15, 2);
            $table->string('reference_type', 100)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->string('description', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['wallet_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
        Schema::dropIfExists('wallets');
        Schema::dropIfExists('point_transactions');
        Schema::dropIfExists('member_points');
        Schema::dropIfExists('point_configs');

        Schema::table('members', function (Blueprint $table) {
            $table->dropConstrainedForeignId('tier_id');
            $table->dropColumn(['birthday', 'qr_token', 'visit_count', 'last_visit_at']);
        });

        Schema::dropIfExists('tier_configs');
    }
};