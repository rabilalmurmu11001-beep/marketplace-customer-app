import 'package:flutter/material.dart';

IconData getCategoryIcon(String label) {
  switch (label.toLowerCase().trim()) {
    case 'cleaning':
    case 'home cleaning':
      return Icons.cleaning_services_outlined;
    case 'repair':
      return Icons.build_outlined;
    case 'painting':
      return Icons.format_paint_outlined;
    case 'plumbing':
      return Icons.plumbing_outlined;
    case 'electric':
    case 'electrician':
    case 'electrical':
      return Icons.electrical_services_outlined;
    case 'laundry':
      return Icons.local_laundry_service_outlined;
    case 'appliance':
      return Icons.kitchen_outlined;
    case 'beauty':
      return Icons.spa_outlined;
    case 'sofa':
    case 'sofa care':
    case 'sofa cleaning':
      return Icons.weekend_outlined;
    case 'ac':
    case 'ac servicing':
    case 'ac service':
      return Icons.ac_unit_outlined;
    case 'garden':
    case 'garden care':
      return Icons.yard_outlined;
    case 'pest control':
    case 'pest':
      return Icons.bug_report_outlined;
    default:
      return Icons.construction_outlined;
  }
}
