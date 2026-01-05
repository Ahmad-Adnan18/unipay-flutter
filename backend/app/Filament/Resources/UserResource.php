<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Filament\Resources\UserResource\RelationManagers;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';
    
    protected static ?string $navigationLabel = 'Mahasiswa';
    
    protected static ?string $modelLabel = 'Mahasiswa';
    
    protected static ?string $pluralModelLabel = 'Mahasiswa';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\FileUpload::make('profile_photo_path')
                    ->label('Foto Profil')
                    ->image()
                    ->avatar()
                    ->directory('profile-photos')
                    ->visibility('public')
                    ->columnSpanFull(),
                Forms\Components\Toggle::make('is_active')
                    ->label('Status Akun (Aktif)')
                    ->default(true)
                    ->columnSpanFull(),
                Forms\Components\Toggle::make('is_admin')
                    ->label('Akses Admin Panel')
                    ->default(false)
                    ->columnSpanFull(),
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('email')
                    ->email()
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('nim')
                    ->label('NIM')
                    ->maxLength(255),
                Forms\Components\Select::make('major')
                    ->label('Prodi')
                    ->options(\App\Models\Major::all()->pluck('name', 'name'))
                    ->searchable()
                    ->native(false)
                    ->required(),
                Forms\Components\TextInput::make('semester')
                    ->label('Semester')
                    ->numeric()
                    ->maxValue(14),
                Forms\Components\TextInput::make('phone')
                    ->label('No HP')
                    ->tel()
                    ->maxLength(255),
                Forms\Components\Textarea::make('address')
                    ->label('Alamat')
                    ->columnSpanFull(),
                Forms\Components\DateTimePicker::make('email_verified_at'),
                Forms\Components\TextInput::make('password')
                    ->password()
                    ->dehydrated(fn ($state) => filled($state))
                    ->required(fn (string $context): bool => $context === 'create')
                    ->maxLength(255),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('profile_photo_path')
                    ->label('Foto')
                    ->circular(),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Status')
                    ->boolean(),
                Tables\Columns\TextColumn::make('name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('nim')
                    ->searchable()
                    ->label('NIM'),
                Tables\Columns\TextColumn::make('major')
                    ->searchable()
                    ->label('Prodi'),
                Tables\Columns\TextColumn::make('semester')
                    ->sortable()
                    ->label('Semester'),
                Tables\Columns\TextColumn::make('phone')
                    ->searchable()
                    ->label('No HP'),
                Tables\Columns\TextColumn::make('address')
                    ->limit(30)
                    ->label('Alamat'),
                Tables\Columns\TextColumn::make('email')
                    ->searchable(),
                Tables\Columns\TextColumn::make('email_verified_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->headerActions([
                Tables\Actions\Action::make('downloadTemplate')
                    ->label('Download Template (Excel)')
                    ->icon('heroicon-o-document-arrow-down')
                    ->url(route('template.mahasiswa'))
                    ->openUrlInNewTab(),
                Tables\Actions\ImportAction::make()
                    ->label('Import Mahasiswa')
                    ->importer(\App\Filament\Imports\UserImporter::class)
                    ->options([
                        'fileTypes' => [
                            'text/csv',
                            'text/plain',
                            'application/vnd.ms-excel',
                            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        ],
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
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
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
