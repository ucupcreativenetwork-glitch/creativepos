<?php

namespace Database\Seeders;

use App\Shared\Support\PaymentMethodCatalog;
use Illuminate\Database\Seeder;

class PaymentMethodSeeder extends Seeder
{
    public function run(): void
    {
        PaymentMethodCatalog::syncToDatabase();
    }
}