class TableServiceRequestModel {
  const TableServiceRequestModel({
    required this.id,
    required this.uuid,
    required this.type,
    required this.status,
    this.outletId,
    this.outletName,
    this.tableNumber,
    this.tableArea,
    this.createdAt,
  });

  final int id;
  final String uuid;
  final String type;
  final String status;
  final int? outletId;
  final String? outletName;
  final String? tableNumber;
  final String? tableArea;
  final String? createdAt;

  String get typeLabel => switch (type) {
        'call_waiter' => 'Panggil Pelayan',
        'request_bill' => 'Minta Tagihan',
        _ => type,
      };

  String get tableLabel {
    final parts = <String>[
      if (tableNumber != null) 'Meja $tableNumber',
      if (tableArea != null) tableArea!,
    ];
    return parts.isEmpty ? 'Meja tamu' : parts.join(' · ');
  }

  factory TableServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return TableServiceRequestModel(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      outletId: json['outlet_id'] as int?,
      outletName: json['outlet_name'] as String?,
      tableNumber: json['table_number'] as String?,
      tableArea: json['table_area'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}