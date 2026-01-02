<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BillController;
use App\Http\Controllers\Api\TransactionController;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/bills', [BillController::class, 'index']);
    Route::post('/pay', [TransactionController::class, 'store']);
    Route::get('/transactions/{order_id}/status', [TransactionController::class, 'checkStatus']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
