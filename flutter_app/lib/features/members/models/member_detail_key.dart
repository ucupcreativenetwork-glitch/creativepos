class MemberDetailKey {
  const MemberDetailKey({required this.id, this.uuid});

  final int id;
  final String? uuid;

  String get pathSegment =>
      uuid != null && uuid!.isNotEmpty ? uuid! : id.toString();

  @override
  bool operator ==(Object other) =>
      other is MemberDetailKey && other.id == id && other.uuid == uuid;

  @override
  int get hashCode => Object.hash(id, uuid);
}