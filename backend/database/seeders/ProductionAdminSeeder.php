<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class ProductionAdminSeeder extends Seeder
{
    public function run(): void
    {
        // Hapus user jika sudah ada (biar bisa reset password)
        User::where('email', 'admin@gmail.com')->delete();

        User::create([
            'name' => 'Admin',
            'email' => 'admin@gmail.com',
            'password' => Hash::make('password'), // Ganti sesuai keinginan nanti
            'email_verified_at' => now(),
            'is_admin' => true,   // PENTING: Filament butuh ini
            'is_active' => true,  // PENTING: Filament butuh ini
            'major' => 'Teknik Informatika', // Default value
            'nim' => 'ADMIN001',
            'semester' => 1,
            'address' => 'Server',
            'phone' => '08123456789',
        ]);
        
        $this->command->info('Admin User created successfully via Seeder!');
    }
}
