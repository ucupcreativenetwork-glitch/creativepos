class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.uuid,
    required this.ticketNumber,
    required this.subject,
    required this.status,
    required this.priority,
    this.channel,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.member,
    this.assignee,
    this.messages = const [],
    this.createdAt,
  });

  final int id;
  final String uuid;
  final String ticketNumber;
  final String subject;
  final String status;
  final String priority;
  final String? channel;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final TicketMember? member;
  final TicketAssignee? assignee;
  final List<TicketMessage> messages;
  final String? createdAt;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      ticketNumber: json['ticket_number'] as String? ?? '',
      subject: json['subject'] as String,
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String? ?? 'medium',
      channel: json['channel'] as String?,
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      member: json['member'] != null
          ? TicketMember.fromJson(json['member'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] != null
          ? TicketAssignee.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }
}

class TicketMember {
  const TicketMember({
    required this.id,
    required this.name,
    this.memberCode,
    this.email,
    this.phone,
  });

  final int id;
  final String name;
  final String? memberCode;
  final String? email;
  final String? phone;

  factory TicketMember.fromJson(Map<String, dynamic> json) {
    return TicketMember(
      id: json['id'] as int,
      name: json['name'] as String,
      memberCode: json['member_code'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class TicketAssignee {
  const TicketAssignee({
    required this.id,
    required this.name,
    this.email,
  });

  final int id;
  final String name;
  final String? email;

  factory TicketAssignee.fromJson(Map<String, dynamic> json) {
    return TicketAssignee(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
    );
  }
}

class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.senderType,
    required this.message,
    this.sender,
    this.isInternal = false,
    this.createdAt,
  });

  final int id;
  final String senderType;
  final String message;
  final TicketAssignee? sender;
  final bool isInternal;
  final String? createdAt;

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int,
      senderType: json['sender_type'] as String? ?? 'customer',
      message: json['message'] as String? ?? '',
      sender: json['sender'] != null
          ? TicketAssignee.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      isInternal: json['is_internal'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}

class FaqModel {
  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    this.sortOrder = 0,
  });

  final int id;
  final String question;
  final String answer;
  final int sortOrder;

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}