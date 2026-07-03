import '../../features/auth/models/user_model.dart';

bool sessionCan(AuthSession? session, String permission) {
  if (session == null) return false;
  if (session.user.roles.contains('super-admin')) return true;
  return session.permissions.contains(permission);
}