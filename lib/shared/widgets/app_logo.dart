import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Reusable widget for displaying the app logo
/// Provides consistent logo display across the application
class AppLogo extends StatelessWidget {
  final double? size;
  final double? width;
  final double? height;
  final Color? fallbackIconColor;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.fallbackIconColor,
    this.fit = BoxFit.contain,
  });

  /// Small logo for app bars and compact spaces
  const AppLogo.small({
    super.key,
    this.fallbackIconColor,
    this.fit = BoxFit.contain,
  }) : size = 24,
       width = null,
       height = null;

  /// Medium logo for login screens and cards
  const AppLogo.medium({
    super.key,
    this.fallbackIconColor,
    this.fit = BoxFit.contain,
  }) : size = 64,
       width = null,
       height = null;

  /// Large logo for splash screens and about dialogs
  const AppLogo.large({
    super.key,
    this.fallbackIconColor,
    this.fit = BoxFit.contain,
  }) : size = 128,
       width = null,
       height = null;

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? 48;
    final logoWidth = width ?? logoSize;
    final logoHeight = height ?? logoSize;
    final iconColor = fallbackIconColor ?? Theme.of(context).primaryColor;

    return Image.asset(
      AppConstants.logoMediumIcon,
      width: logoWidth,
      height: logoHeight,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to material icon if image fails to load
        return Icon(
          Icons.account_balance,
          size: logoSize,
          color: iconColor,
        );
      },
    );
  }
}

/// Hero widget that combines logo with app name and description
class AppBrand extends StatelessWidget {
  final bool showDescription;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final double logoSize;

  const AppBrand({
    super.key,
    this.showDescription = true,
    this.titleStyle,
    this.descriptionStyle,
    this.logoSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          style: titleStyle ?? theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        if (showDescription) ...[
          const SizedBox(height: 8),
          Text(
            'Sistem Informasi Monitoring Pajak Negara',
            style: descriptionStyle ?? theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}