import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.blue,
      elevation: 2,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              color: textColor ?? Colors.white,
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}