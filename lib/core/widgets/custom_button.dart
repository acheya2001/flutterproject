import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isOutlined;
  final bool isCompact;
  final bool isFullWidth;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.color,
    this.isOutlined = false,
    this.isCompact = false,
    this.isFullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color ?? Theme.of(context).primaryColor,
                side: BorderSide(color: color ?? Theme.of(context).primaryColor),
                padding: isCompact 
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(text),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: isCompact 
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(text),
            ),
    );
  }
}
