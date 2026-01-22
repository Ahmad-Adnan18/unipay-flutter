<?php

namespace App\Filament\Exports;

use App\Models\User;
use Filament\Actions\Exports\ExportColumn;
use Filament\Actions\Exports\Exporter;
use Filament\Actions\Exports\Models\Export;

class UserExporter extends Exporter
{
    protected static ?string $model = User::class;

    public static function getColumns(): array
    {
        return [
            ExportColumn::make('name')
                ->label('Nama'),
            
            ExportColumn::make('nim')
                ->label('NIM'),

            ExportColumn::make('email')
                ->label('Email'),

            ExportColumn::make('major')
                ->label('Program Studi'),

            ExportColumn::make('semester')
                ->label('Semester'),

            ExportColumn::make('phone')
                ->label('No HP'),

            ExportColumn::make('address')
                ->label('Alamat'),

            ExportColumn::make('is_active')
                ->label('Status Akun')
                ->formatStateUsing(fn ($state) => $state ? 'Aktif' : 'Nonaktif'),

            ExportColumn::make('created_at')
                ->label('Tanggal Daftar')
                ->formatStateUsing(fn ($state) => $state ? $state->format('d/m/Y H:i') : '-'),
        ];
    }

    public static function getCompletedNotificationBody(Export $export): string
    {
        $body = 'Data mahasiswa berhasil diexport dan ' . number_format($export->successful_rows) . ' data telah tersimpan.';

        if ($failedRowsCount = $export->getFailedRowsCount()) {
            $body .= ' ' . number_format($failedRowsCount) . ' data gagal diexport.';
        }

        return $body;
    }
}
