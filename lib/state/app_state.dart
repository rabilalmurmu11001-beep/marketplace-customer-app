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

  ThemeMode currentThemeMode = ThemeMode.dark;

  void toggleTheme(bool isDark) {
    currentThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  int chosenDateIndex = 1;
  String chosenTimeSlot = '02:00 PM';
  int chosenAddressId = 1;
  bool isFulfillmentPipelineRunning = false;

  final List<Address> customerAddresses = [
    Address(id: 1, label: 'Home Flat 🏠', street: '821 West End Dr', apt: 'Apt 4B', city: 'New York', isDefault: true),
    Address(id: 2, label: 'Office Suite 💼', street: '350 Fifth Ave', apt: 'Floor 42', city: 'New York', isDefault: false),
  ];

  final List<ChatMessage> messageStream = [
    ChatMessage(sender: 'provider', text: 'Hello Emma! I will arrive at your location coords in 20 minutes.', time: '10:30 AM'),
    ChatMessage(sender: 'customer', text: 'Perfect, thank you! Please make sure to bring the non-toxic chemical solvents.', time: '10:32 AM'),
  ];

  Address get activeAddress =>
      customerAddresses.firstWhere((a) => a.id == chosenAddressId, orElse: () => customerAddresses[0]);

  String get activeDateString {
    final List<String> days = ['Sun 24', 'Mon 25', 'Tue 26'];
    if (chosenDateIndex >= 0 && chosenDateIndex < days.length) {
      return days[chosenDateIndex];
    }
    return 'Mon 25';
  }

  void selectAddress(int id) {
    chosenAddressId = id;
    notifyListeners();
  }

  void selectDate(int index) {
    chosenDateIndex = index;
    notifyListeners();
  }

  void selectTimeSlot(String time) {
    chosenTimeSlot = time;
    notifyListeners();
  }

  void bookFulfillment() {
    isFulfillmentPipelineRunning = true;
    notifyListeners();
  }

  void addChatMessage(String text) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    messageStream.add(ChatMessage(sender: 'customer', text: text, time: timeStr));
    notifyListeners();
  }

  void resetJourney() {
    chosenDateIndex = 1;
    chosenTimeSlot = '02:00 PM';
    chosenAddressId = 1;
    isFulfillmentPipelineRunning = false;
    messageStream.clear();
    messageStream.add(ChatMessage(sender: 'provider', text: 'Hello Emma! I will arrive at your location coords in 20 minutes.', time: '10:30 AM'));
    messageStream.add(ChatMessage(sender: 'customer', text: 'Perfect, thank you! Please make sure to bring the non-toxic chemical solvents.', time: '10:32 AM'));
    notifyListeners();
  }
}
