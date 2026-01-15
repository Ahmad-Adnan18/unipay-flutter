<?php

namespace App\Filament\Exports;

use App\Models\Transaction;
use Filament\Actions\Exports\ExportColumn;
use Filament\Actions\Exports\Exporter;
use Filament\Actions\Exports\Models\Export;

class TransactionExporter extends Exporter
{
    protected static ?string $model = Transaction::class;

    public static function getColumns(): array
    {
        return [
            ExportColumn::make('created_at')
                ->label('Tanggal')
                ->formatStateUsing(fn ($state) => $state ? $state->format('d/m/Y H:i') : '-'),
            
            ExportColumn::make('order_id')
                ->label('Order ID'),

            ExportColumn::make('bill.user.name')
                ->label('Nama Mahasiswa'),

            ExportColumn::make('bill.user.nis')
                ->label('NIM'),
            
            ExportColumn::make('bill.title')
                ->label('Keterangan Tagihan'),

            ExportColumn::make('payment_type')
                ->label('Metode Bayar')
                ->formatStateUsing(fn ($state) => strtoupper(str_replace('_', ' ', $state))),

            ExportColumn::make('payment_status')
                ->label('Status'),

            ExportColumn::make('bill.amount')
                ->label('Nominal')
                ->formatStateUsing(fn ($state) => 'Rp ' . number_format($state, 0, ',', '.')),
        ];
    }

    public static function getCompletedNotificationBody(Export $export): string
    {
        $body = 'Laporan transaksi berhasil diexport dan ' . number_format($export->successful_rows) . ' data telah tersimpan.';

        if ($failedRowsCount = $export->getFailedRowsCount()) {
            $body .= ' ' . number_format($failedRowsCount) . ' data gagal diexport.';
        }

        return $body;
    }
}
