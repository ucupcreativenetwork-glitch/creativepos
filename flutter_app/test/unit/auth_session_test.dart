import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/auth/models/user_model.dart';

void main() {
  group('AuthSession', () {
    test('parses login response from API', () {
      final session = AuthSession.fromJson({
        'token': 'test-token-123',
        'requires_2fa': false,
        'user': {
          'id': 1,
          'uuid': 'uuid-1',
          'name': 'Owner Demo',
          'email': 'owner@demo.com',
          'status': 'active',
          'roles': ['owner'],
        },
        'tenant': {
          'id': 10,
          'name': 'Toko Demo',
          'slug': 'toko-demo',
        },
        'permissions': ['dashboard.view', 'pos.create'],
      });

      expect(session.token, 'test-token-123');
      expect(session.user.name, 'Owner Demo');
      expect(session.tenant?.slug, 'toko-demo');
      expect(session.permissions, contains('pos.create'));
      expect(session.isAuthenticated, isTrue);
    });

    test('detects 2FA required', () {
      final session = AuthSession.fromJson({
        'requires_2fa': true,
        'pending_token': 'pending-abc',
        'two_factor_method': 'totp',
        'user': {
          'id': 1,
          'uuid': 'u',
          'name': 'User',
          'email': 'u@demo.com',
        },
      });

      expect(session.requires2fa, isTrue);
      expect(session.pendingToken, 'pending-abc');
      expect(session.isAuthenticated, isFalse);
    });
  });
}