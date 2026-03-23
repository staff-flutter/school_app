import 'package:flutter/material.dart';
import 'package:school_app/models/school_models.dart';

class ClassUtils {
  static IconData getClassIcon(String className) {
    final lower = className.toLowerCase();
    if (lower.contains('lkg') || lower.contains('l.kg')) return Icons.child_care;
    if (lower.contains('ukg') || lower.contains('u.kg')) return Icons.child_friendly;
    if (lower.contains('grade') || lower.contains('class')) {
      final match = RegExp(r'(\d+)').firstMatch(className);
      if (match != null) {
        final num = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (num <= 5) return Icons.looks_one;
        if (num <= 8) return Icons.looks_two;
        return Icons.looks_3;
      }
    }
    return Icons.class_;
  }

  static int _getClassOrder(String className) {
    final lower = className.toLowerCase().trim();
    
    // Handle LKG and UKG first (check contains for flexibility)
    if (lower.contains('lkg')) return 0;
    if (lower.contains('ukg')) return 1;
    
    // Map Roman numerals to numbers
    final romanMap = {
      'i': 1, 'ii': 2, 'iii': 3, 'iv': 4, 'v': 5,
      'vi': 6, 'vii': 7, 'viii': 8, 'ix': 9, 'x': 10,
      'xi': 11, 'xii': 12
    };
    
    // Remove common prefixes (Grade, Class) and trim
    String normalized = lower.replaceAll(RegExp(r'^(grade|class)\s*'), '').trim();
    
    // Check if it's a Roman numeral (after removing prefix)
    if (romanMap.containsKey(normalized)) {
      return 2 + romanMap[normalized]!;
    }
    
    // Check for numeric classes (with or without prefix)
    final match = RegExp(r'(\d+)').firstMatch(className);
    if (match != null) {
      final num = int.tryParse(match.group(1) ?? '0') ?? 0;
      return 2 + num;
    }
    
    return 999;
  }

  static List<SchoolClass> sortClasses(List<SchoolClass> classes) {
    final sorted = List<SchoolClass>.from(classes);
    sorted.sort((a, b) => _getClassOrder(a.name).compareTo(_getClassOrder(b.name)));
    return sorted;
  }
}
