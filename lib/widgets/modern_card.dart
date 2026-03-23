import 'package:flutter/material.dart';
import 'package:school_app/core/theme/app_theme.dart';

class ModernCard {
  static Widget build({
    required Widget child,
    LinearGradient? gradient,
    Color? accentColor,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    final effectiveGradient = gradient ?? AppTheme.cardGradient;
    final effectiveAccentColor = accentColor ?? AppTheme.primaryBlue;
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            effectiveGradient.colors.first.withOpacity(0.08),
            effectiveGradient.colors.last.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: effectiveAccentColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget iconContainer({
    required IconData icon,
    required Color color,
    double size = 24,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
