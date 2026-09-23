import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_satvik_oils/models/customer_model.dart';
import 'package:flutter_application_satvik_oils/providers/sales_provider.dart';

CustomerModel member(String id) => CustomerModel(
  id: id,
  name: 'Member $id',
  phone: '9000000000',
  address: 'Address',
  createdAt: DateTime(2026),
  isMembership: true,
  membershipFee: 500,
);

void main() {
  test('clears a selected customer when membership is removed', () {
    final provider = SalesProvider();
    final customer = member('member-1');

    provider.selectCustomer(customer);
    provider.syncMembershipCustomers(const []);

    expect(provider.selectedCustomer, isNull);
  });

  test('keeps a selected customer while membership remains active', () {
    final provider = SalesProvider();
    final customer = member('member-1');

    provider.selectCustomer(customer);
    provider.syncMembershipCustomers([customer]);

    expect(provider.selectedCustomer, same(customer));
  });
}
