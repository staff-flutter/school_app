import 'package:flutter/material.dart';

class SchoolLogoHelper {
  static void showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildSchoolLogoWidget({
    required Map<String, dynamic>? logo,
    required double size,
    required BuildContext context,
    Color? fallbackColor,
    IconData fallbackIcon = Icons.school,
  }) {
    if (logo != null && logo['url'] != null && logo['url']!.isNotEmpty) {
      return GestureDetector(
        onTap: () => showFullScreenImage(context, logo['url']),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            logo['url'],
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fallbackColor ?? Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                fallbackIcon,
                size: size * 0.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        fallbackIcon,
        size: size * 0.5,
        color: Colors.grey.shade600,
      ),
    );
  }
}