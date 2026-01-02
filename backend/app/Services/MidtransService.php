<?php

namespace App\Services;

use Midtrans\Config;
use Midtrans\CoreApi;

class MidtransService
{
    public function __construct()
    {
        Config::$serverKey = config('services.midtrans.server_key');
        Config::$isProduction = config('services.midtrans.is_production');
        Config::$isSanitized = true;
        Config::$is3ds = true;
    }

    public function chargeQr($orderId, $amount)
    {
        $params = [
            'payment_type' => 'qris',
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $amount,
            ],
            'qris' => [
                'acquirer' => 'gopay',
            ],
        ];

        try {
            return CoreApi::charge($params);
        } catch (\Exception $e) {
            throw new \Exception('Midtrans Charge Failed: ' . $e->getMessage());
        }
    }

    public function checkStatus($orderId)
    {
        try {
            return CoreApi::transactionStatus($orderId);
        } catch (\Exception $e) {
            throw new \Exception('Midtrans Check Status Failed: ' . $e->getMessage());
        }
    }
}
