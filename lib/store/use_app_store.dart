import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerProfileNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setProfile(Map<String, dynamic>? profile) {
    state = profile;
  }
}

class HomeCategoriesNotifier extends Notifier<List<Map<String, dynamic>>?> {
  @override
  List<Map<String, dynamic>>? build() => null;

  void setCategories(List<Map<String, dynamic>>? categories) {
    state = categories;
  }
}

class HomeRecommendedServicesNotifier
    extends Notifier<List<Map<String, dynamic>>?> {
  @override
  List<Map<String, dynamic>>? build() => null;

  void setRecommendedServices(List<Map<String, dynamic>>? services) {
    state = services;
  }
}

class HomeCouponsServiceNotifier extends Notifier<List<Map<String, dynamic>>?> {
  @override
  List<Map<String, dynamic>>? build() => null;

  void setCoupons(List<Map<String, dynamic>>? coupons) {
    state = coupons;
  }
}

class ServiceListingServicesNotifier
    extends Notifier<List<Map<String, dynamic>>?> {
  @override
  List<Map<String, dynamic>>? build() => null;

  void setServices(List<Map<String, dynamic>>? services) {
    state = services;
  }
}

class CustomerAddressNotifier extends Notifier<List<Map<String, dynamic>>?> {
  @override
  List<Map<String, dynamic>>? build() => null;

  void setCustomerAddress(List<Map<String, dynamic>>? address) {
    state = address;
  }
}

///////////////////////////////////////////////////////////////////////////////
//////////// Riverpod Providers  /////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

final customerProfileProvider =
    NotifierProvider<CustomerProfileNotifier, Map<String, dynamic>?>(
      CustomerProfileNotifier.new,
    );

final homeCategoriesProvider =
    NotifierProvider<HomeCategoriesNotifier, List<Map<String, dynamic>>?>(
      HomeCategoriesNotifier.new,
    );

final homeRecommendedServicesProvider =
    NotifierProvider<
      HomeRecommendedServicesNotifier,
      List<Map<String, dynamic>>?
    >(HomeRecommendedServicesNotifier.new);

final homeCouponsProvider =
    NotifierProvider<HomeCouponsServiceNotifier, List<Map<String, dynamic>>?>(
      HomeCouponsServiceNotifier.new,
    );

final serviceListingServiceProvider =
    NotifierProvider<
      ServiceListingServicesNotifier,
      List<Map<String, dynamic>>?
    >(ServiceListingServicesNotifier.new);

final customerAddressProvider =
    NotifierProvider<CustomerAddressNotifier, List<Map<String, dynamic>>?>(
      CustomerAddressNotifier.new,
    );
