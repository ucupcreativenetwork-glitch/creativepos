class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String? createdAt;

  bool get isRead => readAt != null && readAt!.isNotEmpty;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}