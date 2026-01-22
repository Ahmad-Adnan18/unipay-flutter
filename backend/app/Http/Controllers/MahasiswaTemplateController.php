<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use OpenSpout\Writer\XLSX\Writer;
use OpenSpout\Common\Entity\Row;

class MahasiswaTemplateController extends Controller
{
    public function download()
    {
        // Create temp file
        $tempFile = tempnam(sys_get_temp_dir(), 'template_mahasiswa_');
        
        try {
            $writer = new Writer();
            $writer->openToFile($tempFile);

            // Header row
            $headerRow = Row::fromValues([
                'name', 
                'email', 
                'nim', 
                'major', 
                'semester', 
                'phone', 
                'address', 
                'password'
            ]);
            $writer->addRow($headerRow);

            // Example row 1
            $exampleRow1 = Row::fromValues([
                'Ahmad Fatih', 
                'ahmad@example.com', 
                '220101010', 
                'Teknik Informatika', 
                '3', 
                '08123456789', 
                'Jl. Kampus No. 123', 
                'password123'
            ]);
            $writer->addRow($exampleRow1);

            // Example row 2 (optional, biar lebih jelas)
            $exampleRow2 = Row::fromValues([
                'Budi Santoso', 
                'budi@example.com', 
                '220101011', 
                'Sistem Informasi', 
                '5', 
                '08198765432', 
                'Jl. Merdeka No. 45', 
                'budi123'
            ]);
            $writer->addRow($exampleRow2);

            $writer->close();

            // Download the file
            return response()->download($tempFile, 'template_mahasiswa.xlsx')->deleteFileAfterSend(true);
            
        } catch (\Exception $e) {
            // Clean up temp file if error
            if (file_exists($tempFile)) {
                unlink($tempFile);
            }
            throw $e;
        }
    }
}
