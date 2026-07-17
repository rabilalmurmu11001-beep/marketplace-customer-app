import 'package:flutter/material.dart';

class Address {
  final int id;
  final String label;
  final String street;
  final String apt;
  final String city;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.apt,
    required this.city,
    required this.isDefault,
  });
}

class ChatMessage {
  final String sender; // 'customer' or 'provider'
  final String text;
  final String time;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
  });
}

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  ThemeMode currentThemeMode = ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    currentThemeMode = mode;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  DateTime chosenDate = DateTime.now();
  String chosenTimeSlot = '02:00 PM';
  int chosenAddressId = 1;
  String bookingDescription = '';
  bool isFulfillmentPipelineRunning = false;

  final List<Address> customerAddresses = [
    Address(id: 1, label: 'Home Flat', street: '821 West End Dr', apt: 'Apt 4B', city: 'New York', isDefault: true),
    Address(id: 2, label: 'Office Suite', street: '350 Fifth Ave', apt: 'Floor 42', city: 'New York', isDefault: false),
  ];

  final List<ChatMessage> messageStream = [
    ChatMessage(sender: 'provider', text: 'Hello Emma! I will arrive at your location coords in 20 minutes.', time: '10:30 AM'),
    ChatMessage(sender: 'customer', text: 'Perfect, thank you! Please make sure to bring the non-toxic chemical solvents.', time: '10:32 AM'),
  ];

  Address get activeAddress =>
      customerAddresses.firstWhere((a) => a.id == chosenAddressId, orElse: () => customerAddresses[0]);

  String get activeDateString {
    final weekdayStr = _getWeekdayString(chosenDate.weekday);
    return '$weekdayStr ${chosenDate.day}';
  }

  String _getWeekdayString(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  void selectAddress(int id) {
    chosenAddressId = id;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    chosenDate = date;
    notifyListeners();
  }

  void selectTimeSlot(String time) {
    chosenTimeSlot = time;
    notifyListeners();
  }

  void updateBookingDescription(String description) {
    bookingDescription = description;
    notifyListeners();
  }

  void bookFulfillment() {
    isFulfillmentPipelineRunning = true;
    notifyListeners();
  }

  void cancelBooking() {
    isFulfillmentPipelineRunning = false;
    notifyListeners();
  }

  void addAddress({
    required String label,
    required String street,
    required String apt,
    required String city,
    required bool isDefault,
  }) {
    final nextId = customerAddresses.isEmpty
        ? 1
        : customerAddresses.map((a) => a.id).reduce((max, id) => id > max ? id : max) + 1;
        
    final newAddr = Address(
      id: nextId,
      label: label,
      street: street,
      apt: apt,
      city: city,
      isDefault: isDefault,
    );

    if (isDefault) {
      for (int i = 0; i < customerAddresses.length; i++) {
        final a = customerAddresses[i];
        if (a.isDefault) {
          customerAddresses[i] = Address(
            id: a.id,
            label: a.label,
            street: a.street,
            apt: a.apt,
            city: a.city,
            isDefault: false,
          );
        }
      }
    }
    
    customerAddresses.add(newAddr);
    notifyListeners();
  }

  void removeAddress(int id) {
    customerAddresses.removeWhere((a) => a.id == id);
    if (chosenAddressId == id && customerAddresses.isNotEmpty) {
      chosenAddressId = customerAddresses.first.id;
    }
    notifyListeners();
  }

  void setDefaultAddress(int id) {
    for (int i = 0; i < customerAddresses.length; i++) {
      final a = customerAddresses[i];
      customerAddresses[i] = Address(
        id: a.id,
        label: a.label,
        street: a.street,
        apt: a.apt,
        city: a.city,
        isDefault: a.id == id,
      );
    }
    notifyListeners();
  }

  void addChatMessage(String text) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    messageStream.add(ChatMessage(sender: 'customer', text: text, time: timeStr));
    notifyListeners();
  }

  void resetJourney() {
    chosenDate = DateTime.now();
    chosenTimeSlot = '02:00 PM';
    chosenAddressId = 1;
    bookingDescription = '';
    isFulfillmentPipelineRunning = false;
    customerAddresses.clear();
    customerAddresses.addAll([
      Address(id: 1, label: 'Home Flat', street: '821 West End Dr', apt: 'Apt 4B', city: 'New York', isDefault: true),
      Address(id: 2, label: 'Office Suite', street: '350 Fifth Ave', apt: 'Floor 42', city: 'New York', isDefault: false),
    ]);
    messageStream.clear();
    messageStream.add(ChatMessage(sender: 'provider', text: 'Hello Emma! I will arrive at your location coords in 20 minutes.', time: '10:30 AM'));
    messageStream.add(ChatMessage(sender: 'customer', text: 'Perfect, thank you! Please make sure to bring the non-toxic chemical solvents.', time: '10:32 AM'));
    notifyListeners();
  }
}
