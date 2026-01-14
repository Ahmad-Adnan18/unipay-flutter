<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bill;
use App\Models\Transaction;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

class TransactionController extends Controller
{
    protected $midtrans;

    public function __construct(MidtransService $midtrans)
    {
        $this->midtrans = $midtrans;
    }

    public function store(Request $request)
    {
        $request->validate([
            'bill_id' => 'required|exists:bills,id',
            'payment_type' => 'required|in:qris,gopay,shopeepay,va_bca,va_bni,va_bri,va_mandiri,va_permata',
        ]);

        $bill = Bill::findOrFail($request->bill_id);
        $paymentType = $request->payment_type;

        if ($bill->status === 'PAID') {
            return response()->json(['message' => 'Tagihan sudah lunas'], 400);
        }

        // Idempotency: Cek transaksi pending yang belum kadaluarsa dengan payment_type yang sama
        $pendingTx = Transaction::where('bill_id', $bill->id)
            ->where('payment_status', 'pending')
            ->where('payment_type', $paymentType)
            ->where('expiry_time', '>', now())
            ->first();

        if ($pendingTx) {
            return response()->json([
                'data' => [
                    'order_id' => $pendingTx->order_id,
                    'payment_type' => $pendingTx->payment_type,
                    'qr_string' => $pendingTx->qr_string,
                    'payment_instructions' => json_decode($pendingTx->payment_instructions, true),
                    'amount' => $pendingTx->bill->amount,
                    'expiry_time' => $pendingTx->expiry_time,
                ]
            ]);
        }

        // Expire old pending transactions for this bill
        Transaction::where('bill_id', $bill->id)
            ->where('payment_status', 'pending')
            ->update(['payment_status' => 'expire']);

        // Create New Transaction
        $orderId = 'UKT-' . $bill->id . '-' . Str::random(5);
        
        try {
            // Call appropriate Midtrans method based on payment type
            $midtransResponse = $this->callMidtrans($orderId, (int)$bill->amount, $paymentType);
            Log::info('Midtrans Response for Order ' . $orderId, (array)$midtransResponse);
            
            // Extract payment data based on payment type
            $paymentData = $this->extractPaymentData($midtransResponse, $paymentType);
            
            $expiryTime = now()->addMinutes(15);

            $transaction = Transaction::create([
                'bill_id' => $bill->id,
                'order_id' => $orderId,
                'payment_type' => $paymentType,
                'qr_string' => $paymentData['qr_string'] ?? '',
                'payment_instructions' => json_encode($paymentData['instructions'] ?? []),
                'expiry_time' => $expiryTime,
                'payment_status' => 'pending',
                'midtrans_response' => json_decode(json_encode($midtransResponse), true),
            ]);

            return response()->json([
                'data' => [
                    'order_id' => $transaction->order_id,
                    'payment_type' => $transaction->payment_type,
                    'qr_string' => $transaction->qr_string,
                    'payment_instructions' => $paymentData['instructions'] ?? [],
                    'amount' => $bill->amount,
                    'expiry_time' => $transaction->expiry_time,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Transaction creation failed: ' . $e->getMessage());
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    /**
     * Call appropriate Midtrans method based on payment type
     */
    private function callMidtrans(string $orderId, int $amount, string $paymentType): object
    {
        return match(true) {
            str_starts_with($paymentType, 'va_') => $this->midtrans->chargeVA($orderId, $amount, str_replace('va_', '', $paymentType)),
            in_array($paymentType, ['gopay', 'shopeepay']) => $this->midtrans->chargeEwallet($orderId, $amount, $paymentType),
            default => $this->midtrans->chargeQr($orderId, $amount),
        };
    }

    /**
     * Extract payment data from Midtrans response based on payment type
     */
    private function extractPaymentData(object $response, string $paymentType): array
    {
        $data = [
            'qr_string' => '',
            'instructions' => [],
        ];

        // Handle QRIS
        if ($paymentType === 'qris') {
            $qrString = '';
            if (isset($response->actions) && is_array($response->actions)) {
                foreach ($response->actions as $action) {
                    if ($action->name === 'generate-qr-code') {
                        $qrString = $action->url;
                        break;
                    }
                }
            }
            
            if (empty($qrString)) {
                $rawQr = $response->actions[0]->url ?? $response->qr_string ?? '';
                if (filter_var($rawQr, FILTER_VALIDATE_URL)) {
                    $qrString = $rawQr;
                } else {
                    $qrString = 'https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=' . urlencode($rawQr);
                }
            }
            
            $data['qr_string'] = $qrString;
        }

        // Handle Virtual Account
        if (str_starts_with($paymentType, 'va_')) {
            $vaNumbers = $response->va_numbers ?? [];
            if (!empty($vaNumbers)) {
                $va = $vaNumbers[0];
                $data['instructions'] = [
                    'bank' => $va->bank ?? str_replace('va_', '', $paymentType),
                    'va_number' => $va->va_number ?? '',
                ];
            }
            
            // Handle Permata (different structure)
            if (isset($response->permata_va_number)) {
                $data['instructions'] = [
                    'bank' => 'permata',
                    'va_number' => $response->permata_va_number,
                ];
            }
        }

        // Handle E-Wallet (GoPay, ShopeePay)
        if (in_array($paymentType, ['gopay', 'shopeepay'])) {
            $actions = $response->actions ?? [];
            $deeplink = '';
            $qrUrl = '';
            
            foreach ($actions as $action) {
                if ($action->name === 'deeplink-redirect') {
                    $deeplink = $action->url;
                }
                if ($action->name === 'generate-qr-code') {
                    $qrUrl = $action->url;
                }
            }
            
            $data['qr_string'] = $qrUrl;
            $data['instructions'] = [
                'deeplink' => $deeplink,
                'qr_url' => $qrUrl,
            ];
        }

        return $data;
    }

    public function checkStatus($orderId)
    {
        $transaction = Transaction::where('order_id', $orderId)->firstOrFail();

        // If already settled in our DB, return immediately
        if ($transaction->payment_status === 'settlement') {
            return response()->json([
                'data' => [
                    'status' => 'settlement',
                    'paid_at' => $transaction->updated_at,
                ]
            ]);
        }

        try {
            // Hit Midtrans to get latest status
            $statusResponse = $this->midtrans->checkStatus($orderId);
            $transactionStatus = $statusResponse->transaction_status;
            
            // Map Midtrans status to our DB status
            $transaction->payment_status = $transactionStatus;
            $transaction->save();
            
            if ($transactionStatus === 'settlement' || $transactionStatus === 'capture') {
                $bill = $transaction->bill;
                $bill->status = 'PAID';
                $bill->save();
            }

            return response()->json([
                'data' => [
                    'status' => $transactionStatus,
                    'paid_at' => now(), 
                ]
            ]);

        } catch (\Exception $e) {
             return response()->json(['message' => $e->getMessage()], 500);
        }
    }
}
