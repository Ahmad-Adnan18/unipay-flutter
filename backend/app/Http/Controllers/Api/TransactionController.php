<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bill;
use App\Models\Transaction;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

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
        ]);

        $bill = Bill::findOrFail($request->bill_id);

        if ($bill->status === 'PAID') {
            return response()->json(['message' => 'Tagihan sudah lunas'], 400);
        }

        // Idempotency: Cek transaksi pending yang belum kadaluarsa
        $pendingTx = Transaction::where('bill_id', $bill->id)
            ->where('payment_status', 'pending')
            ->where('expiry_time', '>', now())
            ->first();

        if ($pendingTx) {
            return response()->json([
                'data' => [
                    'order_id' => $pendingTx->order_id,
                    'qr_string' => $pendingTx->qr_string,
                    'amount' => $pendingTx->bill->amount,
                    'expiry_time' => $pendingTx->expiry_time,
                ]
            ]);
        }

        // Expire old pending transactions if any
        Transaction::where('bill_id', $bill->id)
            ->where('payment_status', 'pending')
            ->update(['payment_status' => 'expire']);

        // Create New Transaction
        $orderId = 'UKT-' . $bill->id . '-' . Str::random(5);
        
        try {
            $midtransResponse = $this->midtrans->chargeQr($orderId, (int)$bill->amount);
            
            // Assuming Midtrans response structure (adjust based on actual response)
            $qrString = $midtransResponse->actions[0]->url ?? ''; 
            
            // Adjust to robustly find QR string if needed
            if (isset($midtransResponse->qr_string)) {
                $qrString = $midtransResponse->qr_string;
            }

            $expiryTime = now()->addMinutes(15);

            $transaction = Transaction::create([
                'bill_id' => $bill->id,
                'order_id' => $orderId,
                'qr_string' => $qrString, // In real Midtrans Core API, getting the QR String might differ slightly
                'expiry_time' => $expiryTime,
                'payment_status' => 'pending',
                'midtrans_response' => json_decode(json_encode($midtransResponse), true),
            ]);

            return response()->json([
                'data' => [
                    'order_id' => $transaction->order_id,
                    'qr_string' => $transaction->qr_string,
                    'amount' => $bill->amount,
                    'expiry_time' => $transaction->expiry_time,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    public function checkStatus($orderId)
    {
        $transaction = Transaction::where('order_id', $orderId)->firstOrFail();

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
            // Note: In Sandbox, manual simulation is needed to change status on Midtrans side first.
            $statusResponse = $this->midtrans->checkStatus($orderId);
            $transactionStatus = $statusResponse->transaction_status;
            
            // Map Midtrans status to our DB status
            // Core API statuses: capture, settlement, pending, deny, cancel, expire, failure
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
