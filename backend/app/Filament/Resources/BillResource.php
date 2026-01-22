<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BillResource\Pages;
use App\Filament\Resources\BillResource\RelationManagers;
use App\Models\Bill;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class BillResource extends Resource
{
    protected static ?string $model = Bill::class;

    protected static bool $shouldRegisterNavigation = false;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('user_id')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->label('Mahasiswa'),
                Forms\Components\TextInput::make('amount')
                    ->required()
                    ->numeric()
                    ->prefix('Rp')
                    ->label('Jumlah Tagihan'),
                Forms\Components\TextInput::make('title')
                    ->required()
                    ->maxLength(255)
                    ->label('Judul Tagihan'),
                Forms\Components\DatePicker::make('due_date')
                    ->required()
                    ->label('Jatuh Tempo'),
                Forms\Components\Select::make('status')
                    ->options([
                        'UNPAID' => 'Belum Lunas',
                        'PAID' => 'Lunas',
                    ])
                    ->required()
                    ->default('UNPAID'),
                Forms\Components\DateTimePicker::make('locked_at')
                    ->label('Kunci Tagihan (Opsional)'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Mahasiswa')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('title')
                    ->label('Judul')
                    ->searchable(),
                Tables\Columns\TextColumn::make('amount')
                    ->label('Jumlah')
                    ->money('IDR')
                    ->sortable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'PAID' => 'success',
                        'UNPAID' => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('due_date')
                    ->label('Jatuh Tempo')
                    ->date('d M Y')
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'UNPAID' => 'Belum Lunas',
                        'PAID' => 'Lunas',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('mark_paid')
                    ->label('Lunas')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->action(fn (Bill $record) => $record->update(['status' => 'PAID']))
                    ->visible(fn (Bill $record) => $record->status === 'UNPAID'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),

                ]),
            ])
            ->headerActions([
                Tables\Actions\Action::make('create_bulk')
                    ->label('Buat Tagihan Massal')
                    ->icon('heroicon-o-currency-dollar')
                    ->form([
                        Forms\Components\Select::make('scope')
                            ->label('Target Tagihan')
                            ->options([
                                'all' => 'Semua Mahasiswa',
                                'prodi' => 'Berdasarkan Prodi',
                                'semester' => 'Berdasarkan Semester',
                                'prodi_semester' => 'Prodi & Semester',
                                'single' => 'Perorangan',
                            ])
                            ->required()
                            ->reactive(),
                        
                        Forms\Components\Select::make('user_id')
                            ->label('Mahasiswa')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->preload()
                            ->visible(fn (Forms\Get $get) => $get('scope') === 'single')
                            ->required(fn (Forms\Get $get) => $get('scope') === 'single'),

                        Forms\Components\TextInput::make('major_target')
                            ->label('Prodi')
                            ->visible(fn (Forms\Get $get) => in_array($get('scope'), ['prodi', 'prodi_semester']))
                            ->required(fn (Forms\Get $get) => in_array($get('scope'), ['prodi', 'prodi_semester'])),

                        Forms\Components\TextInput::make('semester_target')
                            ->label('Semester')
                            ->numeric()
                            ->visible(fn (Forms\Get $get) => in_array($get('scope'), ['semester', 'prodi_semester']))
                            ->required(fn (Forms\Get $get) => in_array($get('scope'), ['semester', 'prodi_semester'])),

                        // Bill Details
                        Forms\Components\TextInput::make('title')
                            ->label('Judul Tagihan')
                            ->required(),
                        Forms\Components\TextInput::make('amount')
                            ->label('Jumlah (Rp)')
                            ->numeric()
                            ->required(),
                        Forms\Components\DatePicker::make('due_date')
                            ->label('Jatuh Tempo')
                            ->required(),
                    ])
                    ->action(function (array $data) {
                        $query = \App\Models\User::query();

                        if ($data['scope'] === 'single') {
                            $query->where('id', $data['user_id']);
                        } elseif ($data['scope'] === 'prodi') {
                            $query->where('major', $data['major_target']);
                        } elseif ($data['scope'] === 'semester') {
                            $query->where('semester', $data['semester_target']);
                        } elseif ($data['scope'] === 'prodi_semester') {
                            $query->where('major', $data['major_target'])
                                  ->where('semester', $data['semester_target']);
                        }
                        // 'all' doesn't need a filter, it takes all users

                        $users = $query->get();
                        
                        if ($users->isEmpty()) {
                            \Filament\Notifications\Notification::make()
                                ->title('Tidak ada mahasiswa ditemukan')
                                ->warning()
                                ->send();
                            return;
                        }

                        foreach ($users as $user) {
                            // Check for active scholarship
                            $activeScholarship = $user->getActiveScholarship();
                            $originalAmount = $data['amount'];
                            $finalAmount = $originalAmount;
                            $discountAmount = 0;
                            $scholarshipId = null;

                            if ($activeScholarship) {
                                $scholarshipId = $activeScholarship->id;
                                $discountAmount = $activeScholarship->calculateDiscount($originalAmount);
                                $finalAmount = $originalAmount - $discountAmount;
                            }

                            \App\Models\Bill::create([
                                'user_id' => $user->id,
                                'title' => $data['title'],
                                'original_amount' => $activeScholarship ? $originalAmount : null,
                                'scholarship_id' => $scholarshipId,
                                'discount_amount' => $discountAmount,
                                'amount' => $finalAmount,
                                'due_date' => $data['due_date'],
                                'status' => 'UNPAID',
                            ]);
                        }

                        \Filament\Notifications\Notification::make()
                            ->title('Berhasil membuat tagihan untuk ' . $users->count() . ' mahasiswa')
                            ->success()
                            ->send();
                    }),
                    
                Tables\Actions\CreateAction::make()
                    ->label('Buat Tagihan Tunggal'),
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
            'index' => Pages\ListBills::route('/'),
            'create' => Pages\CreateBill::route('/create'),
            'edit' => Pages\EditBill::route('/{record}/edit'),
        ];
    }
}
