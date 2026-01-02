<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'bill_id',
        'order_id',
        'qr_string',
        'expiry_time',
        'payment_status',
        'midtrans_response',
    ];

    protected $casts = [
        'expiry_time' => 'datetime',
        'midtrans_response' => 'array',
    ];

    public function bill()
    {
        return $this->belongsTo(Bill::class);
    }
}
