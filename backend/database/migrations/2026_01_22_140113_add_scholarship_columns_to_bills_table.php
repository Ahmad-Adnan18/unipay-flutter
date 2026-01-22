<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('bills', function (Blueprint $table) {
            $table->decimal('original_amount', 15, 2)->nullable()->after('amount');
            $table->foreignId('scholarship_id')->nullable()->after('original_amount')->constrained()->nullOnDelete();
            $table->decimal('discount_amount', 15, 2)->default(0)->after('scholarship_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bills', function (Blueprint $table) {
            $table->dropForeign(['scholarship_id']);
            $table->dropColumn(['original_amount', 'scholarship_id', 'discount_amount']);
        });
    }
};
