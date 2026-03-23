import 'package:flutter/material.dart';
import 'package:school_app/core/theme/app_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool soft;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient ?? (soft ? null : AppTheme.primaryGradient),
        color: soft ? AppTheme.cardBackground : null,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final String subject;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool soft;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppTheme.getSubjectGradient(subject, soft: soft),
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}