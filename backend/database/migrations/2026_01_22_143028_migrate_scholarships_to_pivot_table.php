<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Migrate existing scholarship->user_id relationships to pivot table
        $scholarships = DB::table('scholarships')->whereNotNull('user_id')->get();
        
        foreach ($scholarships as $scholarship) {
            DB::table('scholarship_user')->insert([
                'scholarship_id' => $scholarship->id,
                'user_id' => $scholarship->user_id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Restore user_id back to scholarships table (if needed for rollback)
        $pivots = DB::table('scholarship_user')->get();
        
        foreach ($pivots as $pivot) {
            DB::table('scholarships')
                ->where('id', $pivot->scholarship_id)
                ->update(['user_id' => $pivot->user_id]);
        }
    }
};
