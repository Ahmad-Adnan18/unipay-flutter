<?php

namespace App\Filament\Pages;

use Filament\Pages\Page;
use Illuminate\Support\Facades\Artisan;
use Filament\Notifications\Notification;
use Illuminate\Support\Facades\Storage;

class Backups extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-server';
    protected static ?string $navigationLabel = 'System Backup';
    protected static ?string $title = 'System Backups';
    protected static ?string $slug = 'backups';
    protected static ?int $navigationSort = 100;

    protected static string $view = 'filament.pages.backups';

    public function createBackup()
    {
        try {
            // Disable DB backup in local env to avoid mysqldump requirement
            if (app()->environment('local')) {
                config(['backup.backup.source.databases' => []]);
            }
            
            Artisan::call('backup:run');
            Notification::make()->title('Backup Berhasil!')->success()->send();
        } catch (\Exception $e) {
            Notification::make()->title('Backup Gagal: ' . $e->getMessage())->danger()->send();
        }
    }

    public function downloadBackup($file)
    {
        return Storage::disk('backups')->download($file);
    }
    
    public function deleteBackup($file)
    {
        Storage::disk('backups')->delete($file);
        Notification::make()->title('File dihapus')->success()->send();
    }

    protected function getViewData(): array
    {
        $backupName = config('backup.backup.name');
        $files = collect(Storage::disk('backups')->files($backupName))
            ->map(function ($file) {
                return [
                    'name' => basename($file),
                    'path' => $file,
                    'size' => $this->formatSize(Storage::disk('backups')->size($file)),
                    'date' => date('Y-m-d H:i:s', Storage::disk('backups')->lastModified($file)),
                ];
            })
            ->sortByDesc('date');

        return [
            'backups' => $files,
        ];
    }
    
    private function formatSize($bytes)
    {
        if ($bytes >= 1073741824) return number_format($bytes / 1073741824, 2) . ' GB';
        if ($bytes >= 1048576) return number_format($bytes / 1048576, 2) . ' MB';
        if ($bytes >= 1024) return number_format($bytes / 1024, 2) . ' KB';
        return $bytes . ' bytes';
    }
}
