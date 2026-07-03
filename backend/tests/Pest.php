<?php

use Tests\DatabaseTestCase;

pest()->extend(DatabaseTestCase::class)->in('Feature');

expect()->extend('toBeOne', function () {
    return $this->toBe(1);
});

function calculateCashChange(float $tendered, float $applied): float
{
    return round(max(0, $tendered - $applied), 2);
}