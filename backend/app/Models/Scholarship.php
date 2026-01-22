<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Scholarship extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'type',
        'amount',
        'category',
        'valid_from',
        'valid_until',
        'is_active',
        'description',
    ];

    protected $casts = [
        'valid_from' => 'date',
        'valid_until' => 'date',
        'is_active' => 'boolean',
        'amount' => 'decimal:2',
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function bills()
    {
        return $this->hasMany(Bill::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where('valid_from', '<=', Carbon::now())
            ->where('valid_until', '>=', Carbon::now());
    }

    // Accessors
    public function getFormattedAmountAttribute()
    {
        if ($this->type === 'percentage') {
            return $this->amount . '%';
        }
        return 'Rp ' . number_format($this->amount, 0, ',', '.');
    }

    public function getStatusBadgeAttribute()
    {
        $now = Carbon::now();
        
        if (!$this->is_active) {
            return 'Nonaktif';
        }
        
        if ($now->lt($this->valid_from)) {
            return 'Belum Berlaku';
        }
        
        if ($now->gt($this->valid_until)) {
            return 'Kedaluwarsa';
        }
        
        return 'Aktif';
    }

    // Helper method untuk calculate discount
    public function calculateDiscount($originalAmount)
    {
        if ($this->type === 'percentage') {
            return $originalAmount * ($this->amount / 100);
        }
        
        return min($this->amount, $originalAmount); // Discount tidak boleh lebih dari amount
    }
}
