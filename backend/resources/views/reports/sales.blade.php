@extends('reports.layout')

@section('content')
<table>
    <thead>
        <tr>
            @foreach($headings as $heading)
                <th>{{ $heading }}</th>
            @endforeach
        </tr>
    </thead>
    <tbody>
        @foreach($rows as $row)
            <tr>
                <td>{{ $row['period'] }}</td>
                <td class="text-right">{{ number_format($row['revenue'], 0, ',', '.') }}</td>
                <td class="text-right">{{ $row['transactions'] }}</td>
                <td class="text-right">{{ number_format($row['discount_total'], 0, ',', '.') }}</td>
                <td class="text-right">{{ number_format($row['tax_total'], 0, ',', '.') }}</td>
            </tr>
        @endforeach
        @if(!empty($totals))
            <tr class="total-row">
                <td>TOTAL</td>
                <td class="text-right">{{ number_format($totals['revenue'], 0, ',', '.') }}</td>
                <td class="text-right">{{ $totals['transactions'] }}</td>
                <td class="text-right">{{ number_format($totals['discount_total'], 0, ',', '.') }}</td>
                <td class="text-right">{{ number_format($totals['tax_total'], 0, ',', '.') }}</td>
            </tr>
        @endif
    </tbody>
</table>
@endsection