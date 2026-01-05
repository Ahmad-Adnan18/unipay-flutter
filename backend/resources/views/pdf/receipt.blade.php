<!DOCTYPE html>
<html>
<head>
    <title>Official Receipt</title>
    <style>
        body { font-family: sans-serif; color: #333; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #ddd; padding-bottom: 10px; }
        .logo { font-size: 24px; font-weight: bold; color: #2ecc71; }
        .title { font-size: 18px; margin-top: 5px; font-weight: bold; }
        .content { margin: 20px; }
        .row { display: flex; justify-content: space-between; margin-bottom: 10px; } /* Flex doesn't work well in DomPDF sometimes, use table */
        table { width: 100%; margin-bottom: 20px; }
        td { padding: 5px; }
        .label { font-weight: bold; color: #666; }
        .amount { font-size: 20px; font-weight: bold; color: #2ecc71; }
        .footer { text-align: center; margin-top: 50px; font-size: 0.8em; color: #999; }
        .status-paid { color: white; background-color: #2ecc71; padding: 5px 10px; border-radius: 5px; font-weight: bold; display: inline-block; }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">UniPay Campus</div>
        <div class="title">OFFICIAL RECEIPT</div>
    </div>

    <div class="content">
        <div style="text-align: center; margin-bottom: 20px;">
            <span class="status-paid">LUNAS / PAID</span>
        </div>

        <table>
            <tr>
                <td class="label">Receipt No:</td>
                <td>#{{ $transaction->order_id }}</td>
            </tr>
            <tr>
                <td class="label">Date:</td>
                <td>{{ $transaction->updated_at->format('d F Y H:i') }}</td>
            </tr>
            <tr>
                <td class="label">Student:</td>
                <td>{{ $transaction->bill->user->name }} ({{ $transaction->bill->user->nim ?? '-' }})</td>
            </tr>
            <tr>
                <td class="label">Payment For:</td>
                <td>{{ $transaction->bill->title }}</td>
            </tr>
            <tr>
                <td class="label">Amount:</td>
                <td class="amount">Rp {{ number_format($transaction->bill->amount, 0, ',', '.') }}</td>
            </tr>
        </table>

        <div style="text-align: center; margin-top: 30px;">
            <p>This receipt is generated automatically and is valid without a signature.</p>
            {{-- <img src="data:image/png;base64,{{ base64_encode(QrCode::format('png')->size(100)->generate($transaction->order_id)) }}" alt="QR Validation" /> --}}
            {!! QrCode::format('svg')->size(100)->generate($transaction->order_id) !!}
        </div>
    </div>

    <div class="footer">
        &copy; {{ date('Y') }} UniPay System. All rights reserved.
    </div>
</body>
</html>
