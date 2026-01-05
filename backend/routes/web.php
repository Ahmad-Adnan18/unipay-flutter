<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\MahasiswaTemplateController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/template-mahasiswa', [MahasiswaTemplateController::class, 'download'])->name('template.mahasiswa');
