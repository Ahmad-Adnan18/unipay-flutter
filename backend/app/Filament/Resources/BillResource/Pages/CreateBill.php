<?php

namespace App\Filament\Resources\BillResource\Pages;

use App\Filament\Resources\BillResource;
use App\Models\User;
use Filament\Actions;
use Filament\Resources\Pages\CreateRecord;

class CreateBill extends CreateRecord
{
    protected static string $resource = BillResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        // Get the user
        $user = User::find($data['user_id']);
        
        if ($user) {
            // Check for active scholarship
            $activeScholarship = $user->getActiveScholarship();
            
            if ($activeScholarship) {
                $originalAmount = $data['amount'];
                $discountAmount = $activeScholarship->calculateDiscount($originalAmount);
                $finalAmount = $originalAmount - $discountAmount;
                
                // Update data with scholarship info
                $data['original_amount'] = $originalAmount;
                $data['scholarship_id'] = $activeScholarship->id;
                $data['discount_amount'] = $discountAmount;
                $data['amount'] = $finalAmount;
                
                // Show notification
                \Filament\Notifications\Notification::make()
                    ->title('Beasiswa diterapkan!')
                    ->body("Potongan {$activeScholarship->formatted_amount} dari {$activeScholarship->name}")
                    ->success()
                    ->send();
            }
        }
        
        return $data;
    }
}
