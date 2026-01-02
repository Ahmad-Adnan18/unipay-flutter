<?php

namespace App\Filament\Widgets;

use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    protected function getStats(): array
    {
        $totalRevenue = \App\Models\Bill::where('status', 'PAID')->sum('amount');
        $pendingBills = \App\Models\Bill::where('status', 'UNPAID')->count();
        $totalUsers = \App\Models\User::count();

        return [
            Stat::make('Total Pemasukan', 'Rp ' . number_format($totalRevenue, 0, ',', '.'))
                ->description('Dari semua tagihan lunas')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success'),
            Stat::make('Tagihan Belum Lunas', $pendingBills)
                ->description('Perlu ditindaklanjuti')
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning'),
            Stat::make('Total Mahasiswa', $totalUsers)
                ->description('Terdaftar di sistem')
                ->color('primary'),
        ];
    }
}
