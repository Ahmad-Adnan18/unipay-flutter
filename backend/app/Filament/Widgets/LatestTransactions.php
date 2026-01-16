<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class LatestTransactions extends BaseWidget
{
    protected static ?int $sort = 4;
    protected int | string | array $columnSpan = 'full';
    protected static ?string $heading = 'Transaksi Terakhir';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Transaction::query()
                    ->whereIn('payment_status', ['settlement', 'capture'])
                    ->latest()
                    ->limit(5)
            )
            ->columns([
                Tables\Columns\TextColumn::make('bill.user.name')
                    ->label('Mahasiswa')
                    ->searchable(),
                Tables\Columns\TextColumn::make('bill.amount')
                    ->label('Nominal')
                    ->money('IDR'),
                Tables\Columns\TextColumn::make('payment_type')
                    ->label('Metode')
                    ->formatStateUsing(fn (string $state): string => strtoupper(str_replace('_', ' ', $state)))
                    ->badge(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Waktu')
                    ->dateTime('d M Y, H:i'),
            ])
            ->actions([
                Tables\Actions\Action::make('view')
                    ->url(fn (Transaction $record): string => \App\Filament\Resources\TransactionResource::getUrl('index')) // Redirect to index for simplicity or edit if available
                    ->icon('heroicon-m-eye')
                    ->label('Detail'),
            ]);
    }
}
