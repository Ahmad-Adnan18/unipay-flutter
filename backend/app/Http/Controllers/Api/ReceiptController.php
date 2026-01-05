<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;

class ReceiptController extends Controller
{
    public function getDownloadUrl($id)
    {
        // Ensure user owns this transaction (optional, but recommended via policy)
        
        $url = \Illuminate\Support\Facades\URL::signedRoute(
            'receipt.download', 
            ['id' => $id], 
            now()->addMinutes(30)
        );

        return response()->json(['url' => $url]);
    }

    public function download($id, Request $request) // Request needed for signature validation implicitly handled by middleware, but good form
    {
        if (! $request->hasValidSignature()) {
            abort(403);
        }

        $transaction = Transaction::with(['bill.user'])->findOrFail($id);

        if ($transaction->payment_status !== 'settlement' && $transaction->payment_status !== 'capture') {
            return response()->json(['message' => 'Transaction not paid yet.'], 403);
        }

        $pdf = Pdf::loadView('pdf.receipt', compact('transaction'));

        return $pdf->download('receipt-'.$transaction->order_id.'.pdf');
    }
}
