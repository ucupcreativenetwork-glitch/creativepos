<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->uuid('uuid')->unique();
            $table->string('member_code', 50);
            $table->string('name');
            $table->string('email')->nullable();
            $table->string('phone', 20);
            $table->enum('status', ['active', 'inactive', 'blocked'])->default('active');
            $table->decimal('total_spend', 15, 2)->default(0);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['member_code', 'tenant_id']);
            $table->unique(['phone', 'tenant_id']);
            $table->index('tenant_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('members');
    }
};