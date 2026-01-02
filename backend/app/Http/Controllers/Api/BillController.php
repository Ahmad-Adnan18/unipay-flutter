<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class BillController extends Controller
{
    public function index()
    {
        $bills = auth()->user()->bills()->orderBy('created_at', 'desc')->get();

        return response()->json([
            'data' => $bills
        ]);
    }
}
