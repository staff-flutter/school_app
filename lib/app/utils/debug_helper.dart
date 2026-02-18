import 'dart:convert';

class DebugHelper {
  static void printFullObject(dynamic object, {String? label}) {
    final jsonString = JsonEncoder.withIndent('  ').convert(object);
    final chunks = _splitString(jsonString, 800); // Split into chunks of 800 chars
    
    if (label != null) {
      
    }
    
    for (int i = 0; i < chunks.length; i++) {
      
    }
    
    if (label != null) {
      
    }
  }
  
  static List<String> _splitString(String text, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      chunks.add(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
    }
    return chunks;
  }
}