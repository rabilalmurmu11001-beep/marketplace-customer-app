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

final customerProfileProvider = NotifierProvider<CustomerProfileNotifier, Map<String, dynamic>?>(
  CustomerProfileNotifier.new,
);

final homeCategoriesProvider = NotifierProvider<HomeCategoriesNotifier, List<Map<String, dynamic>>?>(
  HomeCategoriesNotifier.new,
);