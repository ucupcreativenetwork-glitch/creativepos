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
                <td>{{ $row['created_at'] }}</td>
                <td>{{ $row['product_name'] }}</td>
                <td>{{ $row['sku'] ?? '-' }}</td>
                <td>{{ $row['warehouse_name'] ?? '-' }}</td>
                <td>{{ $row['type'] }}</td>
                <td class="text-right">{{ number_format($row['quantity'], 2, ',', '.') }}</td>
                <td class="text-right">{{ number_format($row['before_quantity'], 2, ',', '.') }}</td>
                <td class="text-right">{{ number_format($row['after_quantity'], 2, ',', '.') }}</td>
                <td>{{ $row['notes'] ?? '' }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
@endsection