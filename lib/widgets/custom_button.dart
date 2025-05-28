import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Changé de VoidCallback à VoidCallback?
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final IconData? icon;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed, // Toujours requis mais peut être null
    this.color,
    this.textColor,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.borderRadius,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: color ?? Theme.of(context).primaryColor,
      foregroundColor: textColor ?? Colors.white,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
    );
    
    final buttonChild = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              )
            : Text(text);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed, // onPressed peut être null
        style: buttonStyle,
        child: buttonChild,
      ),
    );
  }
}