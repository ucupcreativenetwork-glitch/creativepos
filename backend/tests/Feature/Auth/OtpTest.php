<?php

use App\Modules\Auth\Enums\OtpChannel;
use App\Modules\Auth\Enums\OtpPurpose;
use App\Modules\Auth\Jobs\SendOtpJob;
use App\Modules\Auth\Models\OtpVerification;
use App\Modules\Auth\Repositories\OtpVerificationRepository;
use App\Modules\Auth\Services\OtpService;
use App\Modules\Notification\Services\WhatsappService;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;

describe('Auth OTP', function (): void {
    it('requests OTP and verifies the correct code', function (): void {
        Queue::fake();

        $this->mock(WhatsappService::class, function ($mock): void {
            $mock->shouldReceive('send')->andReturn(true);
        });

        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant, [
            'phone' => '081299988877',
        ]);

        $sendResponse = $this->postJson('/api/v1/auth/otp/whatsapp', [
            'phone' => $user->phone,
            'purpose' => OtpPurpose::Login->value,
        ]);

        $sendResponse->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['expires_in', 'expires_at']]);

        Queue::assertPushed(SendOtpJob::class);

        /** @var OtpVerificationRepository $repository */
        $repository = app(OtpVerificationRepository::class);
        $otp = $repository->createOtp(
            $user->phone,
            '123456',
            OtpChannel::Whatsapp,
            OtpPurpose::Login,
            $tenant->id,
        );

        $verifyResponse = $this->postJson('/api/v1/auth/otp/verify', [
            'identifier' => $user->phone,
            'code' => '123456',
            'channel' => OtpChannel::Whatsapp->value,
            'purpose' => OtpPurpose::Login->value,
            'device_name' => 'OTP Pest',
        ]);

        $verifyResponse->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token']]);

        expect($otp->fresh()->verified_at)->not->toBeNull();
    });

    it('rejects expired OTP codes', function (): void {
        $tenant = $this->createTenant();
        $phone = '081211122233';

        OtpVerification::query()->create([
            'tenant_id' => $tenant->id,
            'identifier' => $phone,
            'channel' => OtpChannel::Whatsapp,
            'code_hash' => Hash::make('654321'),
            'purpose' => OtpPurpose::Login,
            'attempts' => 0,
            'max_attempts' => 5,
            'expires_at' => now()->subMinute(),
            'created_at' => now()->subMinutes(10),
        ]);

        $response = $this->postJson('/api/v1/auth/otp/verify', [
            'identifier' => $phone,
            'code' => '654321',
            'channel' => OtpChannel::Whatsapp->value,
            'purpose' => OtpPurpose::Login->value,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.code.0', 'OTP is invalid or has expired.');
    });

    it('blocks verification after five wrong attempts', function (): void {
        $tenant = $this->createTenant();
        $phone = '081244455566';

        OtpVerification::query()->create([
            'tenant_id' => $tenant->id,
            'identifier' => $phone,
            'channel' => OtpChannel::Whatsapp,
            'code_hash' => Hash::make('111111'),
            'purpose' => OtpPurpose::Login,
            'attempts' => 5,
            'max_attempts' => 5,
            'expires_at' => now()->addMinutes(5),
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/v1/auth/otp/verify', [
            'identifier' => $phone,
            'code' => '222222',
            'channel' => OtpChannel::Whatsapp->value,
            'purpose' => OtpPurpose::Login->value,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath(
                'errors.code.0',
                'Maximum verification attempts exceeded. Please request a new OTP.',
            );
    });
});