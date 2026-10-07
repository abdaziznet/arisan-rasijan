import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

enum AppLogoSize {
  /// Small icon (36x36) for app bars or compact headers
  small(36),

  /// Medium icon (56x56) for cards or section headers
  medium(56),

  /// Large icon (84x84) for login, lock screens, and dialogs
  large(84),

  /// Hero icon (112x112) for splash screens
  hero(112);

  const AppLogoSize(this.dimension);
  final double dimension;
}

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = AppLogoSize.large,
    this.customSize,
    this.withContainer = false,
    this.containerColor,
    this.borderRadius,
    this.elevation = 0,
  });

  /// Predefined size preset
  final AppLogoSize size;

  /// Custom size dimension overriding [size]
  final double? customSize;

  /// Whether to wrap the logo in a rounded backdrop container
  final bool withContainer;

  /// Background color for the container if [withContainer] is true
  final Color? containerColor;

  /// Border radius for the container
  final BorderRadius? borderRadius;

  /// Optional shadow elevation
  final double elevation;

  static const String assetPath = 'assets/image/Rasijan.png';

  @override
  Widget build(BuildContext context) {
    final dimension = customSize ?? size.dimension;
    final defaultRadius = BorderRadius.circular(dimension * 0.22);

    Widget imageWidget = Semantics(
      label: 'Logo BANI RASIJAN',
      image: true,
      child: ClipRRect(
        borderRadius: borderRadius ?? defaultRadius,
        child: Image.asset(
          assetPath,
          width: dimension,
          height: dimension,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Container(
            width: dimension,
            height: dimension,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: borderRadius ?? defaultRadius,
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              size: dimension * 0.55,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    if (withContainer) {
      final pad = dimension * 0.14;
      return Container(
        width: dimension + (pad * 2),
        height: dimension + (pad * 2),
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: containerColor ?? AppColors.surface,
          borderRadius: borderRadius ?? AppRadii.hero,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08 * elevation),
                    blurRadius: 12 * elevation,
                    offset: Offset(0, 4 * elevation),
                  ),
                ]
              : null,
        ),
        child: Center(child: imageWidget),
      );
    }

    return imageWidget;
  }
}
