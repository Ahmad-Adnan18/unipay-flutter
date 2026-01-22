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
        Schema::create('scholarships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('name'); // Nama beasiswa (e.g., "Beasiswa Prestasi 2024")
            $table->enum('type', ['percentage', 'fixed']); // Tipe potongan
            $table->decimal('amount', 15, 2); // Nilai potongan
            $table->string('category'); // Kategori (Prestasi, Yatim, Ekonomi, KIP, dll)
            $table->date('valid_from'); // Mulai berlaku
            $table->date('valid_until'); // Berakhir
            $table->boolean('is_active')->default(true); // Status aktif/nonaktif
            $table->text('description')->nullable(); // Keterangan tambahan
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('scholarships');
    }
};
