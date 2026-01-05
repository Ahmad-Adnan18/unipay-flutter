<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BillController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\NewsController;
use App\Http\Controllers\Api\ReceiptController;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/bills', [BillController::class, 'index']);
    Route::post('/pay', [TransactionController::class, 'store']);
    Route::get('/transactions/{order_id}/status', [TransactionController::class, 'checkStatus']);
    Route::get('/transactions/{id}/receipt-url', [ReceiptController::class, 'getDownloadUrl']);
    Route::get('/news', [NewsController::class, 'index']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});

Route::get('/receipt/{id}/download', [ReceiptController::class, 'download'])
    ->name('receipt.download')
    ->middleware('signed');

use App\Http\Controllers\Api\WebhookController;
Route::post('/midtrans/callback', [WebhookController::class, 'handle']);
