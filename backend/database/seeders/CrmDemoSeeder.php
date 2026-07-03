<?php

namespace Database\Seeders;

use App\Models\User;
use App\Modules\CRM\Models\Faq;
use App\Modules\CRM\Models\KnowledgeBaseArticle;
use App\Modules\CRM\Models\KnowledgeBaseCategory;
use App\Modules\CRM\Models\SupportTicket;
use App\Modules\CRM\Models\TicketMessage;
use App\Modules\CRM\Models\TicketStatusHistory;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class CrmDemoSeeder extends Seeder
{
    public function run(): void
    {
        $tenants = Tenant::query()->get();

        foreach ($tenants as $tenant) {
            set_tenant($tenant);
            $this->seedForTenant($tenant);
        }
    }

    protected function seedForTenant(Tenant $tenant): void
    {
        if (Faq::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        $this->seedFaqs($tenant);
        $this->seedKnowledgeBase($tenant);
        $this->seedTickets($tenant);
    }

    protected function seedFaqs(Tenant $tenant): void
    {
        $faqs = [
            ['question' => 'Bagaimana cara melakukan reservasi?', 'answer' => 'Anda dapat melakukan reservasi melalui website, telepon, atau langsung ke outlet kami.', 'sort' => 1],
            ['question' => 'Apakah tersedia layanan delivery?', 'answer' => 'Ya, kami menyediakan layanan delivery ke area tertentu. Silakan hubungi customer service untuk info zona pengiriman.', 'sort' => 2],
            ['question' => 'Bagaimana cara menggunakan poin loyalitas?', 'answer' => 'Poin loyalitas dapat ditukar saat transaksi di kasir atau melalui aplikasi member.', 'sort' => 3],
            ['question' => 'Berapa lama waktu respon tiket dukungan?', 'answer' => 'Tim kami berusaha merespons dalam 24 jam kerja sesuai prioritas tiket.', 'sort' => 4],
            ['question' => 'Bagaimana cara mengajukan refund?', 'answer' => 'Ajukan refund melalui tiket dukungan dengan melampirkan bukti transaksi dan alasan pengembalian.', 'sort' => 5],
        ];

        foreach ($faqs as $faq) {
            Faq::query()->create([
                'tenant_id' => $tenant->id,
                'question' => $faq['question'],
                'answer' => $faq['answer'],
                'sort_order' => $faq['sort'],
                'is_active' => true,
                'created_at' => now(),
            ]);
        }
    }

    protected function seedKnowledgeBase(Tenant $tenant): void
    {
        $agent = User::query()->where('tenant_id', $tenant->id)->first();

        $categories = [
            [
                'name' => 'Panduan Pelanggan',
                'slug' => 'panduan-pelanggan',
                'sort_order' => 1,
                'articles' => [
                    ['title' => 'Cara Order Online', 'slug' => 'cara-order-online', 'content' => 'Panduan lengkap memesan melalui menu digital dan aplikasi.'],
                    ['title' => 'Kebijakan Pembatalan', 'slug' => 'kebijakan-pembatalan', 'content' => 'Ketentuan pembatalan pesanan dan reservasi.'],
                ],
            ],
            [
                'name' => 'Panduan Staf',
                'slug' => 'panduan-staf',
                'sort_order' => 2,
                'articles' => [
                    ['title' => 'Menangani Keluhan Pelanggan', 'slug' => 'menangani-keluhan', 'content' => 'Langkah standar menangani keluhan dan eskalasi tiket.'],
                ],
            ],
        ];

        foreach ($categories as $categoryData) {
            $category = KnowledgeBaseCategory::query()->create([
                'tenant_id' => $tenant->id,
                'name' => $categoryData['name'],
                'slug' => $categoryData['slug'],
                'sort_order' => $categoryData['sort_order'],
                'is_active' => true,
            ]);

            foreach ($categoryData['articles'] as $article) {
                KnowledgeBaseArticle::query()->create([
                    'tenant_id' => $tenant->id,
                    'category_id' => $category->id,
                    'title' => $article['title'],
                    'slug' => $article['slug'],
                    'content' => $article['content'],
                    'is_published' => true,
                    'view_count' => rand(10, 200),
                    'created_by' => $agent?->id,
                ]);
            }
        }
    }

    protected function seedTickets(Tenant $tenant): void
    {
        if (SupportTicket::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        $agent = User::query()->where('tenant_id', $tenant->id)->first();
        $members = Member::query()->limit(3)->get();

        $tickets = [
            [
                'subject' => 'Pesanan belum sampai',
                'priority' => 'high',
                'status' => 'open',
                'channel' => 'whatsapp',
                'customer_name' => 'Budi Santoso',
                'customer_phone' => '08111111111',
                'messages' => [
                    ['type' => 'system', 'message' => 'Tiket dukungan telah dibuat.'],
                    ['type' => 'customer', 'message' => 'Pesanan saya belum sampai setelah 2 jam.'],
                ],
            ],
            [
                'subject' => 'Permintaan refund transaksi',
                'priority' => 'medium',
                'status' => 'assigned',
                'channel' => 'email',
                'customer_name' => 'Siti Aminah',
                'customer_email' => 'siti@demo.com',
                'messages' => [
                    ['type' => 'system', 'message' => 'Tiket dukungan telah dibuat.'],
                    ['type' => 'customer', 'message' => 'Saya ingin refund untuk transaksi kemarin.'],
                    ['type' => 'agent', 'message' => 'Baik, kami akan cek detail transaksi Anda.'],
                ],
            ],
            [
                'subject' => 'Poin loyalitas tidak masuk',
                'priority' => 'low',
                'status' => 'pending',
                'channel' => 'website',
                'customer_name' => 'Andi Wijaya',
                'messages' => [
                    ['type' => 'system', 'message' => 'Tiket dukungan telah dibuat.'],
                    ['type' => 'customer', 'message' => 'Poin dari transaksi tadi tidak bertambah.'],
                    ['type' => 'agent', 'message' => 'Sedang kami verifikasi dengan sistem POS.'],
                ],
            ],
            [
                'subject' => 'Kualitas makanan kurang sesuai',
                'priority' => 'critical',
                'status' => 'resolved',
                'channel' => 'phone',
                'customer_name' => 'Dewi Lestari',
                'rating' => 4,
                'messages' => [
                    ['type' => 'system', 'message' => 'Tiket dukungan telah dibuat.'],
                    ['type' => 'customer', 'message' => 'Makanan yang diantar kurang hangat.'],
                    ['type' => 'agent', 'message' => 'Mohon maaf, kami akan kirim penggantian gratis.'],
                ],
            ],
        ];

        foreach ($tickets as $index => $data) {
            $ticket = SupportTicket::query()->create([
                'tenant_id' => $tenant->id,
                'uuid' => (string) Str::uuid(),
                'ticket_number' => 'TKT-'.now()->format('Ymd').'-'.str_pad((string) ($index + 1), 4, '0', STR_PAD_LEFT),
                'member_id' => $members->get($index % max(1, $members->count()))?->id,
                'customer_name' => $data['customer_name'],
                'customer_email' => $data['customer_email'] ?? null,
                'customer_phone' => $data['customer_phone'] ?? null,
                'channel' => $data['channel'],
                'subject' => $data['subject'],
                'priority' => $data['priority'],
                'status' => $data['status'],
                'assigned_to' => in_array($data['status'], ['assigned', 'pending', 'resolved'], true) ? $agent?->id : null,
                'sla_deadline' => now()->addHours(24),
                'first_response_at' => in_array($data['status'], ['assigned', 'pending', 'resolved'], true) ? now()->subHours(2) : null,
                'resolved_at' => $data['status'] === 'resolved' ? now()->subHour() : null,
                'rating' => $data['rating'] ?? null,
            ]);

            TicketStatusHistory::query()->create([
                'ticket_id' => $ticket->id,
                'from_status' => null,
                'to_status' => 'open',
                'changed_by' => null,
                'created_at' => now()->subHours(5),
            ]);

            if ($data['status'] !== 'open') {
                TicketStatusHistory::query()->create([
                    'ticket_id' => $ticket->id,
                    'from_status' => 'open',
                    'to_status' => 'assigned',
                    'changed_by' => $agent?->id,
                    'created_at' => now()->subHours(4),
                ]);
            }

            if (in_array($data['status'], ['pending', 'resolved'], true)) {
                TicketStatusHistory::query()->create([
                    'ticket_id' => $ticket->id,
                    'from_status' => 'assigned',
                    'to_status' => $data['status'],
                    'changed_by' => $agent?->id,
                    'created_at' => now()->subHours(2),
                ]);
            }

            foreach ($data['messages'] as $msgIndex => $msg) {
                TicketMessage::query()->create([
                    'ticket_id' => $ticket->id,
                    'sender_type' => $msg['type'],
                    'sender_id' => $msg['type'] === 'agent' ? $agent?->id : null,
                    'message' => $msg['message'],
                    'is_internal' => false,
                    'created_at' => now()->subHours(5 - $msgIndex),
                ]);
            }
        }
    }
}