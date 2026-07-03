<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('support_tickets', function (Blueprint $table) {
            $table->foreignId('member_id')->nullable()->after('ticket_number')->constrained()->nullOnDelete();
            $table->string('customer_name')->nullable()->after('member_id');
            $table->string('customer_email')->nullable()->after('customer_name');
            $table->string('customer_phone', 20)->nullable()->after('customer_email');
            $table->enum('channel', ['whatsapp', 'telegram', 'email', 'website', 'phone'])->default('website')->after('customer_phone');
            $table->foreignId('assigned_to')->nullable()->after('status')->constrained('users')->nullOnDelete();
            $table->timestamp('sla_deadline')->nullable()->after('assigned_to');
            $table->timestamp('first_response_at')->nullable()->after('sla_deadline');
            $table->timestamp('resolved_at')->nullable()->after('first_response_at');
            $table->timestamp('closed_at')->nullable()->after('resolved_at');
            $table->unsignedTinyInteger('rating')->nullable()->after('closed_at');
            $table->text('rating_comment')->nullable()->after('rating');
        });

        Schema::create('ticket_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ticket_id')->constrained('support_tickets')->cascadeOnDelete();
            $table->enum('sender_type', ['customer', 'agent', 'system']);
            $table->unsignedBigInteger('sender_id')->nullable();
            $table->text('message');
            $table->boolean('is_internal')->default(false);
            $table->timestamp('created_at')->useCurrent();
            $table->index(['ticket_id', 'created_at']);
        });

        Schema::create('ticket_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ticket_id')->constrained('support_tickets')->cascadeOnDelete();
            $table->string('from_status', 30)->nullable();
            $table->string('to_status', 30);
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['ticket_id', 'created_at']);
        });

        Schema::create('faqs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('question');
            $table->text('answer');
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamp('created_at')->useCurrent();
            $table->index(['tenant_id', 'is_active', 'sort_order']);
        });

        Schema::create('knowledge_base_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name', 100);
            $table->string('slug', 120);
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['tenant_id', 'slug']);
            $table->index(['tenant_id', 'is_active', 'sort_order']);
        });

        Schema::create('knowledge_base_articles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('knowledge_base_categories')->cascadeOnDelete();
            $table->string('title');
            $table->string('slug', 150);
            $table->text('content');
            $table->boolean('is_published')->default(false);
            $table->unsignedInteger('view_count')->default(0);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['tenant_id', 'slug']);
            $table->index(['tenant_id', 'category_id', 'is_published']);
        });

        Schema::create('whatsapp_configs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('phone_number', 20);
            $table->text('api_token')->nullable();
            $table->string('webhook_secret', 100)->nullable();
            $table->boolean('is_active')->default(false);
            $table->timestamps();
            $table->unique('tenant_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('whatsapp_configs');
        Schema::dropIfExists('knowledge_base_articles');
        Schema::dropIfExists('knowledge_base_categories');
        Schema::dropIfExists('faqs');
        Schema::dropIfExists('ticket_status_histories');
        Schema::dropIfExists('ticket_messages');

        Schema::table('support_tickets', function (Blueprint $table) {
            $table->dropConstrainedForeignId('member_id');
            $table->dropConstrainedForeignId('assigned_to');
            $table->dropColumn([
                'customer_name',
                'customer_email',
                'customer_phone',
                'channel',
                'sla_deadline',
                'first_response_at',
                'resolved_at',
                'closed_at',
                'rating',
                'rating_comment',
            ]);
        });
    }
};