<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\News;
use Illuminate\Http\Request;

class NewsController extends Controller
{
    public function index()
    {
        $news = News::latest()->take(5)->get()->map(function ($item) {
            return [
                'id' => $item->id,
                'title' => $item->title,
                'content' => $item->content,
                'image_url' => $item->image_url ? asset('storage/' . $item->image_url) : null,
                'created_at' => $item->created_at->diffForHumans(),
            ];
        });

        return response()->json([
            'data' => $news
        ]);
    }
}
