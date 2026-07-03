<?php

namespace App\Modules\Inventory\Imports;

use Maatwebsite\Excel\Concerns\ToArray;

class StockSpreadsheetReader implements ToArray
{
    public function array(array $array): array
    {
        return $array;
    }
}