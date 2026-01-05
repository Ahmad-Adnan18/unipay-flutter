<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use OpenSpout\Writer\XLSX\Writer;
use OpenSpout\Common\Entity\Row;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MahasiswaTemplateController extends Controller
{
    public function download()
    {
        return new StreamedResponse(function () {
            $writer = new Writer();
            $writer->openToBrowser('template_mahasiswa.xlsx');

            // Header row
            $writer->addRow(Row::fromValues([
                'name', 'email', 'nim', 'major', 'semester', 'phone', 'address', 'password'
            ]));

            // Example row
            $writer->addRow(Row::fromValues([
                'Adnan Example', 'adnan@example.com', '12345678', 'Teknik Informatika', 3, '08123456789', 'Jl. Kampus No. 1', 'secret123'
            ]));

            $writer->close();
        });
    }
}
