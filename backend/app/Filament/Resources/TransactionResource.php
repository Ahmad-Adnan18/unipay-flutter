<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TransactionResource\Pages;
use App\Filament\Resources\TransactionResource\RelationManagers;
use App\Models\Transaction;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class TransactionResource extends Resource
{
    protected static ?string $model = Transaction::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('bill_id')
                    ->readOnly()
                    ->numeric(),
                Forms\Components\TextInput::make('order_id')
                    ->readOnly()
                    ->maxLength(255),
                Forms\Components\Textarea::make('qr_string')
                    ->columnSpanFull()
                    ->readOnly(),
                Forms\Components\DateTimePicker::make('expiry_time')
                    ->readOnly(),
                Forms\Components\TextInput::make('payment_status')
                    ->readOnly(),
                Forms\Components\Textarea::make('midtrans_response')
                    ->columnSpanFull()
                    ->readOnly(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('bill.user.name')
                    ->label('Mahasiswa')
                    ->searchable(),
                Tables\Columns\TextColumn::make('order_id')
                    ->searchable()
                    ->copyable()
                    ->label('Order ID'),
                Tables\Columns\TextColumn::make('payment_status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'settlement' => 'success',
                        'capture' => 'success',
                        'pending' => 'warning',
                        'expire' => 'danger',
                        'cancel' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('expiry_time')
                    ->dateTime()
                    ->sortable()
                    ->label('Kedaluwarsa'),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                 Tables\Filters\SelectFilter::make('payment_status')
                    ->options([
                        'settlement' => 'Settlement (Paid)',
                        'pending' => 'Pending',
                        'expire' => 'Expired',
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListTransactions::route('/'),
            'create' => Pages\CreateTransaction::route('/create'),
            'edit' => Pages\EditTransaction::route('/{record}/edit'),
        ];
    }
}
