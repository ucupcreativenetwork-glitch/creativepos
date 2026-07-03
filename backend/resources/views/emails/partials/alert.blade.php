@php
    $alertType = $type ?? 'info';
    $styles = match ($alertType) {
        'success' => 'background-color:#f0fdf4;border:1px solid #bbf7d0;color:#166534;',
        'warning' => 'background-color:#fffbeb;border:1px solid #fde68a;color:#92400e;',
        'danger' => 'background-color:#fef2f2;border:1px solid #fecaca;color:#991b1b;',
        default => 'background-color:#eff6ff;border:1px solid #bfdbfe;color:#1e40af;',
    };
@endphp
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:20px 0;">
    <tr>
        <td style="{{ $styles }}border-radius:10px;padding:16px 18px;font-size:14px;line-height:1.6;">
            {{ $message }}
        </td>
    </tr>
</table>