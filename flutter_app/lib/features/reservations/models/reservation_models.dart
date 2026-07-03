class ReservationModel {
  const ReservationModel({
    required this.id,
    required this.uuid,
    required this.reservationNumber,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.guestCount,
    required this.reservationDate,
    required this.reservationTime,
    required this.status,
    this.notes,
    this.outlet,
    this.member,
    this.table,
    this.confirmedAt,
    this.arrivedAt,
    this.cancelledAt,
    this.createdAt,
  });

  final int id;
  final String uuid;
  final String reservationNumber;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final int guestCount;
  final String reservationDate;
  final String reservationTime;
  final String status;
  final String? notes;
  final ReservationOutlet? outlet;
  final ReservationMember? member;
  final ReservationTable? table;
  final String? confirmedAt;
  final String? arrivedAt;
  final String? cancelledAt;
  final String? createdAt;

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      reservationNumber: json['reservation_number'] as String? ?? '',
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      customerEmail: json['customer_email'] as String?,
      guestCount: json['guest_count'] as int? ?? 1,
      reservationDate: json['reservation_date'] as String? ?? '',
      reservationTime: json['reservation_time'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      outlet: json['outlet'] != null
          ? ReservationOutlet.fromJson(json['outlet'] as Map<String, dynamic>)
          : null,
      member: json['member'] != null
          ? ReservationMember.fromJson(json['member'] as Map<String, dynamic>)
          : null,
      table: json['table'] != null
          ? ReservationTable.fromJson(json['table'] as Map<String, dynamic>)
          : null,
      confirmedAt: json['confirmed_at'] as String?,
      arrivedAt: json['arrived_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ReservationOutlet {
  const ReservationOutlet({
    required this.id,
    required this.name,
    this.code,
  });

  final int id;
  final String name;
  final String? code;

  factory ReservationOutlet.fromJson(Map<String, dynamic> json) {
    return ReservationOutlet(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}

class ReservationMember {
  const ReservationMember({
    required this.id,
    required this.name,
    this.memberCode,
  });

  final int id;
  final String name;
  final String? memberCode;

  factory ReservationMember.fromJson(Map<String, dynamic> json) {
    return ReservationMember(
      id: json['id'] as int,
      name: json['name'] as String,
      memberCode: json['member_code'] as String?,
    );
  }
}

class ReservationTable {
  const ReservationTable({
    required this.id,
    required this.tableNumber,
    this.name,
  });

  final int id;
  final String tableNumber;
  final String? name;

  factory ReservationTable.fromJson(Map<String, dynamic> json) {
    return ReservationTable(
      id: json['id'] as int,
      tableNumber: json['table_number'] as String? ?? '',
      name: json['name'] as String?,
    );
  }
}

class ReservationSlot {
  const ReservationSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.booked,
    required this.available,
    required this.isAvailable,
  });

  final int id;
  final String startTime;
  final String endTime;
  final int capacity;
  final int booked;
  final int available;
  final bool isAvailable;

  factory ReservationSlot.fromJson(Map<String, dynamic> json) {
    return ReservationSlot(
      id: json['id'] as int,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      booked: json['booked'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
    );
  }
}