<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Facades\DB;

class PaymentMethodChart extends ChartWidget
{
    protected static ?string $heading = 'Metode Pembayaran';
    protected static ?int $sort = 3;

    protected function getData(): array
    {
        $data = Transaction::query()
            ->select('payment_type', DB::raw('count(*) as total'))
            ->groupBy('payment_type')
            ->pluck('total', 'payment_type')
            ->all();

        // Standardize labels (remove underscores, uppercase)
        $labels = array_map(function ($key) {
            return strtoupper(str_replace('_', ' ', $key));
        }, array_keys($data));

        return [
            'datasets' => [
                [
                    'label' => 'Transaksi',
                    'data' => array_values($data),
                    'backgroundColor' => [
                        '#3B82F6', // Blue
                        '#10B981', // Green
                        '#F59E0B', // Amber
                        '#EF4444', // Red
                        '#8B5CF6', // Purple
                        '#EC4899', // Pink
                    ],
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }
}
