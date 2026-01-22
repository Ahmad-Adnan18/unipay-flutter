<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListUsers extends ListRecords
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
            Actions\ExportAction::make()
                ->exporter(\App\Filament\Exports\UserExporter::class)
                ->label('Export Data Mahasiswa')
                ->formats([
                    \Filament\Actions\Exports\Enums\ExportFormat::Xlsx,
                ]),
        ];
    }
}
