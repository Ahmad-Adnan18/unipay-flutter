<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ScholarshipResource\Pages;
use App\Filament\Resources\ScholarshipResource\RelationManagers;
use App\Models\Scholarship;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ScholarshipResource extends Resource
{
    protected static ?string $model = Scholarship::class;

    protected static ?string $navigationIcon = 'heroicon-o-academic-cap';
    
    protected static ?string $navigationLabel = 'Beasiswa & Potongan';
    
    protected static ?string $modelLabel = 'Beasiswa';
    
    protected static ?string $pluralModelLabel = 'Beasiswa & Potongan';

    protected static ?int $navigationSort = 4;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('user_id')
                    ->label('Mahasiswa')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->columnSpanFull(),
                
                Forms\Components\TextInput::make('name')
                    ->label('Nama Beasiswa')
                    ->placeholder('e.g., Beasiswa Prestasi 2024')
                    ->required()
                    ->maxLength(255)
                    ->columnSpanFull(),
                
                Forms\Components\Radio::make('type')
                    ->label('Tipe Potongan')
                    ->options([
                        'percentage' => 'Persentase (%)',
                        'fixed' => 'Nominal (Rp)',
                    ])
                    ->required()
                    ->reactive()
                    ->inline()
                    ->columnSpanFull(),
                
                Forms\Components\TextInput::make('amount')
                    ->label(fn (Forms\Get $get) => $get('type') === 'percentage' ? 'Persentase Potongan' : 'Nominal Potongan')
                    ->prefix(fn (Forms\Get $get) => $get('type') === 'percentage' ? '%' : 'Rp')
                    ->numeric()
                    ->required()
                    ->minValue(0)
                    ->maxValue(fn (Forms\Get $get) => $get('type') === 'percentage' ? 100 : null)
                    ->helperText(fn (Forms\Get $get) => $get('type') === 'percentage' ? 'Masukkan angka 1-100 (tanpa simbol %)' : 'Masukkan nominal dalam Rupiah'),
                
                Forms\Components\Select::make('category')
                    ->label('Kategori')
                    ->options([
                        'Prestasi' => 'Prestasi Akademik',
                        'Yatim' => 'Yatim Piatu',
                        'Ekonomi' => 'Tidak Mampu (Ekonomi)',
                        'KIP' => 'KIP (Kartu Indonesia Pintar)',
                        'Hafidz' => 'Hafidz Al-Quran',
                        'Atlet' => 'Atlet/Prestasi Non-Akademik',
                        'Lainnya' => 'Lainnya',
                    ])
                    ->required()
                    ->native(false),
                
                Forms\Components\DatePicker::make('valid_from')
                    ->label('Berlaku Dari')
                    ->required()
                    ->default(now())
                    ->native(false),
                
                Forms\Components\DatePicker::make('valid_until')
                    ->label('Berlaku Sampai')
                    ->required()
                    ->after('valid_from')
                    ->native(false),
                
                Forms\Components\Toggle::make('is_active')
                    ->label('Status Aktif')
                    ->default(true)
                    ->helperText('Nonaktifkan untuk menangguhkan beasiswa tanpa menghapus data'),
                
                Forms\Components\Textarea::make('description')
                    ->label('Keterangan')
                    ->placeholder('Keterangan tambahan (opsional)')
                    ->columnSpanFull()
                    ->rows(3),
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
                
                Tables\Columns\TextColumn::make('user.nim')
                    ->label('NIM')
                    ->searchable(),
                
                Tables\Columns\TextColumn::make('name')
                    ->label('Nama Beasiswa')
                    ->searchable()
                    ->limit(30),
                
                Tables\Columns\TextColumn::make('formatted_amount')
                    ->label('Nilai Potongan')
                    ->badge()
                    ->color('success'),
                
                Tables\Columns\TextColumn::make('category')
                    ->label('Kategori')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Prestasi' => 'info',
                        'Yatim' => 'warning',
                        'Ekonomi' => 'danger',
                        'KIP' => 'primary',
                        default => 'gray',
                    }),
                
                Tables\Columns\TextColumn::make('valid_from')
                    ->label('Berlaku')
                    ->date('d M Y')
                    ->sortable(),
                
                Tables\Columns\TextColumn::make('valid_until')
                    ->label('Sampai')
                    ->date('d M Y')
                    ->sortable(),
                
                Tables\Columns\TextColumn::make('status_badge')
                    ->label('Status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Aktif' => 'success',
                        'Nonaktif' => 'danger',
                        'Kedaluwarsa' => 'warning',
                        'Belum Berlaku' => 'gray',
                        default => 'gray',
                    }),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('category')
                    ->label('Kategori')
                    ->options([
                        'Prestasi' => 'Prestasi Akademik',
                        'Yatim' => 'Yatim Piatu',
                        'Ekonomi' => 'Ekonomi',
                        'KIP' => 'KIP',
                        'Hafidz' => 'Hafidz',
                        'Atlet' => 'Atlet',
                        'Lainnya' => 'Lainnya',
                    ]),
                
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Status Aktif')
                    ->placeholder('Semua')
                    ->trueLabel('Aktif')
                    ->falseLabel('Nonaktif'),
                
                Tables\Filters\SelectFilter::make('type')
                    ->label('Tipe')
                    ->options([
                        'percentage' => 'Persentase',
                        'fixed' => 'Nominal',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('Belum ada data beasiswa')
            ->emptyStateDescription('Silakan tambahkan beasiswa untuk mahasiswa tertentu.')
            ->emptyStateIcon('heroicon-o-academic-cap');
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
            'index' => Pages\ListScholarships::route('/'),
            'create' => Pages\CreateScholarship::route('/create'),
            'edit' => Pages\EditScholarship::route('/{record}/edit'),
        ];
    }
}
