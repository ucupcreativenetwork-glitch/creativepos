                    <tr>
                        <td style="background:linear-gradient(135deg,#1d4ed8 0%,#2563eb 50%,#3b82f6 100%);padding:28px 40px;">
                            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td>
                                        <p style="margin:0 0 4px;font-size:13px;font-weight:600;color:rgba(255,255,255,0.85);letter-spacing:0.5px;text-transform:uppercase;">CreativePOS</p>
                                        <h1 style="margin:0;font-size:24px;font-weight:700;color:#ffffff;line-height:1.3;">{{ $heading }}</h1>
                                        @if (!empty($subtitle))
                                            <p style="margin:8px 0 0;font-size:14px;color:rgba(255,255,255,0.9);line-height:1.5;">{{ $subtitle }}</p>
                                        @endif
                                    </td>
                                    @if (!empty($badge))
                                        <td align="right" valign="top" width="48">
                                            <div style="width:44px;height:44px;background:rgba(255,255,255,0.2);border-radius:12px;text-align:center;line-height:44px;font-size:22px;">{{ $badge }}</div>
                                        </td>
                                    @endif
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:36px 40px 8px;">