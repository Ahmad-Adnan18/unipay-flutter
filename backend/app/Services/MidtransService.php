<?php

namespace App\Services;

use Midtrans\Config;
use Midtrans\CoreApi;
use Midtrans\Transaction;

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
            // 'qris' => [
            //     'acquirer' => 'gopay',
            // ],
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
            return Transaction::status($orderId);
        } catch (\Exception $e) {
            throw new \Exception('Midtrans Check Status Failed: ' . $e->getMessage());
        }
    }

    /**
     * Charge via Bank Transfer (Virtual Account)
     * Supported banks: bca, bni, bri, mandiri, permata, cimb
     */
    public function chargeVA(string $orderId, int $amount, string $bank): object
    {
        $params = [
            'payment_type' => 'bank_transfer',
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $amount,
            ],
            'bank_transfer' => [
                'bank' => $bank,
            ],
        ];

        try {
            return CoreApi::charge($params);
        } catch (\Exception $e) {
            throw new \Exception('Midtrans VA Charge Failed: ' . $e->getMessage());
        }
    }

    /**
     * Charge via E-Wallet (GoPay, ShopeePay)
     */
    public function chargeEwallet(string $orderId, int $amount, string $type): object
    {
        $params = [
            'payment_type' => $type,
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $amount,
            ],
        ];

        try {
            return CoreApi::charge($params);
        } catch (\Exception $e) {
            throw new \Exception('Midtrans E-Wallet Charge Failed: ' . $e->getMessage());
        }
    }
}
