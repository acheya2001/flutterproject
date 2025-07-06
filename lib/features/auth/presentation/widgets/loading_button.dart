import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// 🔄 Bouton avec indicateur de chargement
class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final ButtonStyle? style;

  const LoadingButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.style,
  }) : super(key: key);

  /// 🔄 Factory avec texte et icône
  factory LoadingButton.withTextAndIcon({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    bool isLoading = false,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    double? width,
    double? height,
    ButtonStyle? style,
  }) {
    return LoadingButton(
      key: key,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      padding: padding,
      borderRadius: borderRadius,
      width: width,
      height: height,
      style: style,
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(text),
              ],
            )
          : Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? DesignConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          foregroundColor: foregroundColor ?? AppTheme.textOnPrimary,
          elevation: elevation ?? 2,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: DesignConstants.paddingL,
            vertical: DesignConstants.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(DesignConstants.radiusM),
          ),
          disabledBackgroundColor: backgroundColor?.withValues(alpha: 0.6) ??
              AppTheme.primaryColor.withValues(alpha: 0.6),
          disabledForegroundColor: foregroundColor?.withValues(alpha: 0.6) ??
              AppTheme.textOnPrimary.withValues(alpha: 0.6),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor ?? AppTheme.textOnPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Chargement...'),
                ],
              )
            : child,
      ),
    );
  }
}

/// 🔄 Bouton outlined avec loading
class LoadingOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? borderColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final ButtonStyle? style;

  const LoadingOutlinedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.borderColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? DesignConstants.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? AppTheme.primaryColor,
          side: BorderSide(
            color: borderColor ?? AppTheme.primaryColor,
            width: 1.5,
          ),
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: DesignConstants.paddingL,
            vertical: DesignConstants.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(DesignConstants.radiusM),
          ),
          disabledForegroundColor: foregroundColor?.withValues(alpha: 0.6) ??
              AppTheme.primaryColor.withValues(alpha: 0.6),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor ?? AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Chargement...'),
                ],
              )
            : child,
      ),
    );
  }
}

/// 🔄 Bouton texte avec loading
class LoadingTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final ButtonStyle? style;

  const LoadingTextButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.foregroundColor,
    this.padding,
    this.width,
    this.height,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? TextButton.styleFrom(
          foregroundColor: foregroundColor ?? AppTheme.primaryColor,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: DesignConstants.paddingM,
            vertical: DesignConstants.paddingS,
          ),
          disabledForegroundColor: foregroundColor?.withValues(alpha: 0.6) ??
              AppTheme.primaryColor.withValues(alpha: 0.6),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor ?? AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Chargement...'),
                ],
              )
            : child,
      ),
    );
  }
}

/// 🎯 Bouton d'action flottant avec loading
class LoadingFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final String? tooltip;
  final String? heroTag;

  const LoadingFloatingActionButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.tooltip,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      foregroundColor: foregroundColor ?? AppTheme.textOnPrimary,
      elevation: elevation ?? 6,
      tooltip: tooltip,
      heroTag: heroTag,
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? AppTheme.textOnPrimary,
                ),
              ),
            )
          : child,
    );
  }
}

/// 🔄 Bouton icône avec loading
class LoadingIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;
  final Color? color;
  final double? iconSize;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const LoadingIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.color,
    this.iconSize,
    this.tooltip,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: iconSize ?? 24,
              height: iconSize ?? 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).iconTheme.color ?? AppTheme.primaryColor,
                ),
              ),
            )
          : Icon(
              icon,
              size: iconSize,
              color: color,
            ),
      iconSize: iconSize,
      tooltip: tooltip,
      padding: padding ?? const EdgeInsets.all(8),
    );
  }
}

/// 🎨 Bouton personnalisé avec gradient
class GradientLoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GradientLoadingButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.gradient = const LinearGradient(
      colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
    ),
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? DesignConstants.buttonHeight,
      decoration: BoxDecoration(
        gradient: isLoading ? null : gradient,
        color: isLoading ? AppTheme.primaryColor.withValues(alpha: 0.6) : null,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignConstants.radiusM),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignConstants.radiusM),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: DesignConstants.paddingL,
              vertical: DesignConstants.paddingM,
            ),
            child: isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chargement...',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : DefaultTextStyle(
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ) ?? const TextStyle(color: Colors.white),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}
