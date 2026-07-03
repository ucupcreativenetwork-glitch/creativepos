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
        @foreach($rows as $index => $row)
            <tr>
                <td>{{ $index + 1 }}</td>
                <td>{{ $row['product_name'] }}</td>
                <td>{{ $row['sku'] ?? '-' }}</td>
                <td class="text-right">{{ number_format($row['total_qty'], 0, ',', '.') }}</td>
                <td class="text-right">{{ number_format($row['total_revenue'], 0, ',', '.') }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
@endsection