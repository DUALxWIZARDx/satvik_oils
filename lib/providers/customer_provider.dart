import 'package:flutter/foundation.dart';

import '../models/customer_model.dart';
import '../models/customer_analytics.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider({CustomerRepository? customerRepository})
      : _customerRepository = customerRepository ?? CustomerRepository();

  static const membershipFee = 500.0;
  final CustomerRepository _customerRepository;
  List<CustomerModel> _customers = const [];
  bool _isLoading = false;
  String? _error;
  List<CustomerAnalytics> _analytics = const [];

  List<CustomerModel> get customers => List.unmodifiable(_customers);
  List<CustomerModel> get membershipCustomers =>
      List.unmodifiable(_customers.where((customer) => customer.isMembership));
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CustomerAnalytics> get analytics => List.unmodifiable(_analytics);

  Future<void> loadCustomers() async {
    _isLoading = true; notifyListeners();
    try { _customers = await _customerRepository.getCustomers(); _analytics = await _customerRepository.getCustomerAnalytics(); _error = null; }
    catch (e) { _error = e.toString(); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> saveMembership({CustomerModel? customer, required String name, required String phone, required String address}) async {
    final cleanName = name.trim(), cleanPhone = phone.trim(), cleanAddress = address.trim();
    if (cleanName.isEmpty || cleanPhone.isEmpty || cleanAddress.isEmpty) throw ArgumentError('Name, phone number, and address are required.');
    final samePhone = await _customerRepository.getCustomerByPhone(cleanPhone);
    if (samePhone != null && samePhone.id != customer?.id) {
      if (samePhone.isMembership) throw ArgumentError('This phone number already has a membership customer.');
      customer = samePhone;
    }
    if (customer == null) {
      await _customerRepository.createCustomer(name: cleanName, phone: cleanPhone, address: cleanAddress, isMembership: true, membershipFee: membershipFee);
    } else {
      await _customerRepository.updateCustomer(customer.copyWith(name: cleanName, phone: cleanPhone, address: cleanAddress, isMembership: true, membershipFee: membershipFee));
    }
    await loadCustomers();
  }

  Future<void> removeMembership(CustomerModel customer) async {
    await _customerRepository.updateCustomer(customer.copyWith(isMembership: false, membershipFee: 0));
    await loadCustomers();
  }
}
