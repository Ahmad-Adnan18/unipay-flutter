<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Transaction;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    public function handle(Request $request)
    {
        try {
            // Log incoming request for debugging
            Log::info('Midtrans Webhook Received', $request->all());

            $notif = new \Midtrans\Notification();

            $transaction_status = $notif->transaction_status;
            $type = $notif->payment_type;
            $order_id = $notif->order_id;
            $fraud = $notif->fraud_status;

            $transaction = Transaction::where('order_id', $order_id)->first();

            if (!$transaction) {
                return response()->json(['message' => 'Transaction not found'], 404);
            }

            if ($transaction_status == 'capture') {
                if ($fraud == 'challenge') {
                    $transaction->payment_status = 'challenge';
                } else {
                    $transaction->payment_status = 'settlement';
                }
            } else if ($transaction_status == 'settlement') {
                $transaction->payment_status = 'settlement';
            } else if ($transaction_status == 'pending') {
                $transaction->payment_status = 'pending';
            } else if ($transaction_status == 'deny') {
                $transaction->payment_status = 'deny';
            } else if ($transaction_status == 'expire') {
                $transaction->payment_status = 'expire';
            } else if ($transaction_status == 'cancel') {
                $transaction->payment_status = 'cancel';
            }

            $transaction->save();

            // Check if PAID
            if ($transaction->payment_status === 'settlement') {
                 $transaction->bill->update(['status' => 'PAID']);
            }

            return response()->json(['message' => 'Webhook received']);

        } catch (\Exception $e) {
            Log::error('Midtrans Webhook Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error processing webhook'], 500);
        }
    }
}
