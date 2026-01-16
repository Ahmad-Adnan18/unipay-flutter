<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Filament\Widgets\ChartWidget;
use Flowframe\Trend\Trend;
use Flowframe\Trend\TrendValue;
use Illuminate\Support\Carbon;

class RevenueChart extends ChartWidget
{
    protected static ?string $heading = 'Grafik Pemasukan (Per Bulan)';
    protected static ?int $sort = 2;
    protected int | string | array $columnSpan = 2;

    protected function getData(): array
    {
        // Join with bills table to get the amount
        $query = Transaction::query()
            ->join('bills', 'transactions.bill_id', '=', 'bills.id')
            ->whereIn('transactions.payment_status', ['settlement', 'capture']);

        $data = Trend::query($query)
            ->dateColumn('transactions.created_at')
            ->between(
                start: now()->startOfYear(),
                end: now()->endOfYear(),
            )
            ->perMonth()
            ->sum('bills.amount');

        return [
            'datasets' => [
                [
                    'label' => 'Pemasukan (Rp)',
                    'data' => $data->map(fn (TrendValue $value) => $value->aggregate),
                    'borderColor' => '#10B981', // Emerald 500
                    'fill' => true,
                    'backgroundColor' => 'rgba(16, 185, 129, 0.1)',
                ],
            ],
            'labels' => $data->map(fn (TrendValue $value) => Carbon::parse($value->date)->format('M')),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
