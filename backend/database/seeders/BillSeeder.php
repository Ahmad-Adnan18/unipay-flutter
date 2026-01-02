<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class BillSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $user = \App\Models\User::firstOrCreate(
            ['email' => 'mahasiswa@example.com'],
            [
                'name' => 'Adnan Mahasiswa',
                'password' => bcrypt('password'),
            ]
        );

        \App\Models\Bill::create([
            'user_id' => $user->id,
            'title' => 'UKT Semester Genap 2026',
            'amount' => 5000000,
            'due_date' => now()->addMonth(),
            'status' => 'UNPAID',
        ]);

        \App\Models\Bill::create([
            'user_id' => $user->id,
            'title' => 'Biaya Praktikum Lab',
            'amount' => 750000,
            'due_date' => now()->addWeeks(2),
            'status' => 'UNPAID',
        ]);
        
        $this->command->info('Bills and User seeded!');
    }
}
