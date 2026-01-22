<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PembayaranResource\Pages;
use App\Filament\Resources\PembayaranResource\RelationManagers;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PembayaranResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';

    protected static ?string $navigationLabel = 'Pembayaran';

    protected static ?string $modelLabel = 'Pembayaran Mahasiswa';

    protected static ?string $pluralModelLabel = 'Pembayaran Mahasiswa';

    protected static ?string $slug = 'pembayaran';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->readOnly()
                    ->label('Nama Mahasiswa'),
                Forms\Components\TextInput::make('nim')
                    ->label('NIM')
                    ->readOnly(),
                Forms\Components\TextInput::make('major')
                    ->label('Prodi')
                    ->readOnly(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('profile_photo_path')
                    ->label('Foto')
                    ->circular(),
                Tables\Columns\TextColumn::make('name')
                    ->label('Nama Mahasiswa')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('nim')
                    ->label('NIM')
                    ->searchable(),
                Tables\Columns\TextColumn::make('major')
                    ->label('Prodi')
                    ->searchable(),
                Tables\Columns\TextColumn::make('bills_count')
                    ->counts('bills')
                    ->label('Total Tagihan'),
                 Tables\Columns\TextColumn::make('unpaid_bills_count')
                    ->counts('unpaidBills')
                    ->label('Tagihan Belum Lunas')
                    ->badge()
                    ->color(fn (string $state): string => $state > 0 ? 'danger' : 'success'),
            ])
            ->filters([
                Tables\Filters\Filter::make('has_tunggakan')
                    ->label('Hanya Mahasiswa Tunggakan')
                    ->query(fn ($query) => $query->whereHas('bills', fn ($q) => $q->where('status', 'UNPAID')))
                    ->toggle(),
                Tables\Filters\SelectFilter::make('major')
                    ->label('Prodi')
                    ->options(fn () => \App\Models\Major::pluck('name', 'name')->toArray()),
                Tables\Filters\SelectFilter::make('semester')
                    ->label('Semester')
                    ->options(array_combine(range(1, 14), range(1, 14))),
            ])
            ->modifyQueryUsing(fn ($query) => $query->where('is_admin', false))
            ->description('Untuk mengirim pengingat tagihan via WhatsApp: pilih mahasiswa dengan mencentang checkbox, kemudian gunakan menu "Bulk actions" dan pilih opsi "Kirim WA Tagihan".')
            ->emptyStateHeading('Belum ada data mahasiswa')
            ->emptyStateDescription('Silakan tambahkan mahasiswa terlebih dahulu melalui menu Mahasiswa.')
            ->emptyStateIcon('heroicon-o-users')
            ->actions([
                Tables\Actions\EditAction::make()
                    ->label('Detail Tagihan'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\BulkAction::make('send_whatsapp')
                        ->label('Kirim WA Tagihan')
                        ->icon('heroicon-o-chat-bubble-left-right')
                        ->color('success')
                        ->requiresConfirmation()
                        ->action(function (\Illuminate\Database\Eloquent\Collection $records) {
                            $service = new \App\Services\FonnteService();
                            $count = 0;
                            
                            foreach ($records as $user) {
                                // Calculate total unpaid bills
                                $unpaidBills = $user->bills()->where('status', 'UNPAID')->get();
                                $totalAmount = $unpaidBills->sum('amount');
                                $totalCount = $unpaidBills->count();

                                if ($totalCount > 0 && $user->phone) {
                                    $formattedAmount = number_format($totalAmount, 0, ',', '.');
                                    
                                    $message = "Halo *{$user->name}*,\n\nKami mengingatkan bahwa Anda memiliki *{$totalCount} tagihan* yang belum lunas dengan total *Rp {$formattedAmount}*.\n\nMohon segera lakukan pembayaran melalui aplikasi Unipay.\nKlik link ini untuk buka aplikasi:\n👉 unipay://bills\n\nTerima kasih.";
                                    
                                    if ($service->sendReminder($user->phone, $message)) {
                                        $count++;
                                        // Anti-ban protection: Delay 2 seconds per message
                                        sleep(2);
                                    }
                                }
                            }
                            
                            \Filament\Notifications\Notification::make()
                                ->title("Pesan dikirim ke {$count} mahasiswa")
                                ->success()
                                ->send();
                        })
                        ->deselectRecordsAfterCompletion(),
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
                            ->relationship('user', 'name') // Attempting to use relationship might fail here as User doesn't belong to User in this way? 
                            // Actually, relationship() works on the Model of the RESOURCE usually. But here the resource is User.
                            // However, we are in a Form that is not attached to a record yet.
                            // Better to use options() with search.
                            ->options(User::all()->pluck('name', 'id'))
                            ->searchable()
                            ->visible(fn (Forms\Get $get) => $get('scope') === 'single')
                            ->required(fn (Forms\Get $get) => $get('scope') === 'single'),

                        Forms\Components\Select::make('major_target')
                            ->label('Prodi')
                            ->options(\App\Models\Major::all()->pluck('name', 'name'))
                            ->visible(fn (Forms\Get $get) => in_array($get('scope'), ['prodi', 'prodi_semester']))
                            ->required(fn (Forms\Get $get) => in_array($get('scope'), ['prodi', 'prodi_semester'])),

                        Forms\Components\Select::make('semester_target')
                            ->label('Semester')
                            ->options(array_combine(range(1, 14), range(1, 14)))
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
                            \App\Models\Bill::create([
                                'user_id' => $user->id,
                                'title' => $data['title'],
                                'amount' => $data['amount'],
                                'due_date' => $data['due_date'],
                                'status' => 'UNPAID',
                            ]);
                        }

                        \Filament\Notifications\Notification::make()
                            ->title('Berhasil membuat tagihan untuk ' . $users->count() . ' mahasiswa')
                            ->success()
                            ->send();
                    }),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\BillsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPembayarans::route('/'),
            'edit' => Pages\EditPembayaran::route('/{record}/edit'),
        ];
    }
}
