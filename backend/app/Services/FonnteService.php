<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FonnteService
{
    protected string $baseUrl = 'https://api.fonnte.com';
    protected string $token;

    public function __construct()
    {
        $this->token = config('services.fonnte.token', env('FONNTE_TOKEN'));
    }

    /**
     * Send WhatsApp message to a specific number
     */
    public function sendReminder(string $target, string $message): bool
    {
        if (empty($this->token)) {
            Log::error('Fonnte Token is missing in .env');
            return false;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => $this->token,
            ])->post($this->baseUrl . '/send', [
                'target' => $target,
                'message' => $message,
                'countryCode' => '62', // Default Indonesia
            ]);

            if ($response->successful()) {
                Log::info('WhatsApp sent to ' . $target);
                return true;
            } else {
                Log::error('Fonnte API Error: ' . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error('Fonnte Exception: ' . $e->getMessage());
            return false;
        }
    }
}
