<?php

namespace App\Modules\Notification\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseService
{
    /**
     * @param  list<string>  $tokens
     * @param  array<string, mixed>  $data
     * @return array{success: bool, response?: mixed, error?: string}
     */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): array
    {
        $tokens = array_values(array_filter($tokens));

        if ($tokens === []) {
            return ['success' => false, 'error' => 'No FCM tokens'];
        }

        $serverKey = config('creativepos.notifications.firebase.server_key');

        if (blank($serverKey)) {
            Log::info('Firebase push (dev mode)', [
                'tokens' => $tokens,
                'title' => $title,
                'body' => $body,
                'data' => $data,
            ]);

            return ['success' => true, 'response' => ['mode' => 'dev']];
        }

        $response = Http::withHeaders([
            'Authorization' => 'key='.$serverKey,
            'Content-Type' => 'application/json',
        ])->post('https://fcm.googleapis.com/fcm/send', [
            'registration_ids' => $tokens,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
            ],
            'data' => $data,
            'priority' => 'high',
        ]);

        if (! $response->successful()) {
            return [
                'success' => false,
                'error' => $response->body(),
                'response' => $response->json(),
            ];
        }

        return ['success' => true, 'response' => $response->json()];
    }
}