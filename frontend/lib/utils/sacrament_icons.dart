import 'package:flutter/material.dart';

IconData getSacramentIcon(String? type) {
  switch (type) {
    case 'baptism':
      return Icons.water_drop;
    case 'wedding':
      return Icons.wc;
    case 'confirmation':
      return Icons.local_fire_department;
    case 'eucharist':
      return Icons.breakfast_dining;
    case 'reconciliation':
      return Icons.handshake;
    case 'anointing_sick':
      return Icons.medical_services;
    case 'mass_intention':
      return Icons.church;
    case 'funeral_mass':
      return Icons.local_florist;
    default:
      return Icons.event;
  }
}

String formatDateMMDDYYYY(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final date = DateTime.parse(dateStr);
    final phDate = date.isUtc ? date.add(const Duration(hours: 8)) : date;
    return '${phDate.month.toString().padLeft(2, '0')}/${phDate.day.toString().padLeft(2, '0')}/${phDate.year}';
  } catch (e) {
    return dateStr;
  }
}

String formatDateTimeMMDDYYYY(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final date = DateTime.parse(dateStr);
    final phDate = date.isUtc ? date.add(const Duration(hours: 8)) : date;
    return '${phDate.month.toString().padLeft(2, '0')}/${phDate.day.toString().padLeft(2, '0')}/${phDate.year} ${phDate.hour.toString().padLeft(2, '0')}:${phDate.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return dateStr;
  }
}
