import 'package:flutter_test/flutter_test.dart';

import 'package:ayeyo/features/auth/domain/auth_user.dart';

void main() {
  test('authRoleFromKey maps roles safely', () {
    expect(authRoleFromKey('admin'), AuthRole.admin);
    expect(authRoleFromKey('counter'), AuthRole.counter);
    expect(authRoleFromKey('rider'), AuthRole.rider);
    expect(authRoleFromKey('customer'), AuthRole.customer);
    expect(authRoleFromKey('unknown'), AuthRole.customer);
    expect(authRoleFromKey(null), AuthRole.customer);
  });
}
