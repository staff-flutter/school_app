import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Custom icons class for handling different types of custom icons
class CustomIcons {
  // Private constructor to prevent instantiation
  CustomIcons._();

  /// Creates an icon from SVG asset
  static Widget svgIcon(
    String assetPath, {
    double? size,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      fit: fit,
    );
  }

  /// Creates an icon from PNG/JPG asset
  static Widget imageIcon(
    String assetPath, {
    double? size,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color,
      fit: fit,
    );
  }

  /// Creates a social media icon widget that can handle both SVG and image assets
  static Widget socialMediaIcon(
    String platform, {
    double size = 24,
    bool useSvg = true,
  }) {
    final assetPath = useSvg
        ? 'assets/icons/${platform}.svg'
        : 'assets/icons/${platform}.png';

    final color = _getSocialMediaColor(platform);

    return useSvg
        ? svgIcon(assetPath, size: size, color: color)
        : imageIcon(assetPath, size: size, color: color);
  }

  /// Gets the brand color for social media platforms
  static Color _getSocialMediaColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'linkedin':
        return const Color(0xFF0077B5);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitter':
      case 'x':
        return const Color(0xFF000000);
      case 'tiktok':
        return const Color(0xFF000000);
      default:
        return Colors.grey;
    }
  }

  /// Creates a custom icon button with SVG support
  static Widget iconButton({
    required VoidCallback onPressed,
    required String iconAsset,
    bool isSvg = true,
    double size = 24,
    Color? color,
    EdgeInsetsGeometry? padding,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      padding: padding ?? const EdgeInsets.all(8),
      tooltip: tooltip,
      icon: isSvg
          ? svgIcon(iconAsset, size: size, color: color)
          : imageIcon(iconAsset, size: size, color: color),
    );
  }

  /// Predefined social media icons using custom assets
  static Widget instagramIcon({double size = 24, bool useSvg = true}) =>
      socialMediaIcon('instagram', size: size, useSvg: useSvg);

  static Widget facebookIcon({double size = 24, bool useSvg = true}) =>
      socialMediaIcon('facebook', size: size, useSvg: useSvg);

  static Widget linkedinIcon({double size = 24, bool useSvg = true}) =>
      socialMediaIcon('linkedin', size: size, useSvg: useSvg);

  static Widget youtubeIcon({double size = 24, bool useSvg = true}) =>
      socialMediaIcon('youtube', size: size, useSvg: useSvg);

  static Widget twitterIcon({double size = 24, bool useSvg = true}) =>
      socialMediaIcon('twitter', size: size, useSvg: useSvg);

  static Widget tiktokIcon({double size = 24, bool useSvg = true}) =>
      socialMediaIcon('tiktok', size: size, useSvg: useSvg);
}

/// Extension to easily use custom icons in Icon widgets
extension CustomIconExtension on Icon {
  /// Creates a custom icon from asset
  static Widget fromAsset(
    String assetPath, {
    double? size,
    Color? color,
    bool isSvg = true,
  }) {
    return isSvg
        ? CustomIcons.svgIcon(assetPath, size: size, color: color)
        : CustomIcons.imageIcon(assetPath, size: size, color: color);
  }
}

