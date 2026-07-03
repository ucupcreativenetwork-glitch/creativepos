<?php

namespace App\Modules\Billing\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Billing\Services\Gateways\MidtransGateway;
use App\Modules\Billing\Services\Gateways\XenditGateway;
use App\Modules\Billing\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentWebhookController extends Controller
{
    public function __construct(
        private readonly PaymentService $paymentService,
        private readonly MidtransGateway $midtrans,
        private readonly XenditGateway $xendit,
    ) {}

    public function midtrans(Request $request): JsonResponse
    {
        $payload = $request->all();
        $signature = $payload['signature_key'] ?? '';

        if (filled($signature) && ! $this->midtrans->verifySignature($payload, $signature)) {
            Log::warning('Midtrans webhook signature invalid', ['order_id' => $payload['order_id'] ?? null]);

            return response()->json(['message' => 'Invalid signature'], 403);
        }

        $orderId = $payload['order_id'] ?? null;
        $invoice = $orderId
            ? $this->paymentService->findInvoiceByGatewayOrder($orderId)
            : null;

        if ($invoice === null) {
            $invoiceId = isset($payload['custom_field1']) ? (int) $payload['custom_field1'] : null;
            $invoice = $this->paymentService->findInvoiceByIdFromMetadata($invoiceId);
        }

        if ($invoice === null) {
            return response()->json(['message' => 'Invoice not found'], 404);
        }

        $status = $this->midtrans->parseNotificationStatus($payload);

        if ($status === 'paid') {
            $this->paymentService->markInvoicePaid(
                $invoice,
                'midtrans',
                $invoice->payment_method ?? 'midtrans',
                $payload['transaction_id'] ?? $orderId,
                $payload,
            );
        } else {
            $this->paymentService->updatePaymentStatus($invoice, $status);
        }

        return response()->json(['message' => 'OK']);
    }

    public function xendit(Request $request): JsonResponse
    {
        $token = $request->header('x-callback-token');

        if (! $this->xendit->verifyWebhookToken($token)) {
            if (filled(config('creativepos.payment.xendit.webhook_token'))) {
                Log::warning('Xendit webhook token invalid');

                return response()->json(['message' => 'Invalid token'], 403);
            }
        }

        $payload = $request->all();
        $externalId = $payload['external_id'] ?? null;
        $invoice = $externalId
            ? $this->paymentService->findInvoiceByGatewayOrder($externalId)
            : null;

        if ($invoice === null) {
            $metadata = $payload['metadata'] ?? [];
            $invoiceId = isset($metadata['invoice_id']) ? (int) $metadata['invoice_id'] : null;
            $invoice = $this->paymentService->findInvoiceByIdFromMetadata($invoiceId);
        }

        if ($invoice === null) {
            return response()->json(['message' => 'Invoice not found'], 404);
        }

        $status = $this->xendit->parseInvoiceStatus($payload);

        if ($status === 'paid') {
            $this->paymentService->markInvoicePaid(
                $invoice,
                'xendit',
                $invoice->payment_method ?? 'credit_card',
                $payload['id'] ?? $externalId,
                $payload,
            );
        } else {
            $this->paymentService->updatePaymentStatus($invoice, $status);
        }

        return response()->json(['message' => 'OK']);
    }
}