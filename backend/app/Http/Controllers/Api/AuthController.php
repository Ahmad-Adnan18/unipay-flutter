<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (!auth()->attempt($request->only('email', 'password'))) {
            return response()->json([
                'message' => 'Invalid login details'
            ], 401);
        }

        $user = auth()->user();

        if (!$user->is_active) {
            auth()->user()->tokens()->delete();
            return response()->json([
                'message' => 'Akun Anda telah dinonaktifkan. Silakan hubungi admin.'
            ], 403);
        }
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ]);
    }
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required',
            'new_password' => 'required|min:8|confirmed',
        ]);

        $user = auth()->user();

        if (!\Illuminate\Support\Facades\Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Password lama tidak sesuai.'
            ], 422);
        }

        $user->update([
            'password' => bcrypt($request->new_password)
        ]);

        return response()->json([
            'message' => 'Password berhasil diubah.'
        ]);
    }
}
