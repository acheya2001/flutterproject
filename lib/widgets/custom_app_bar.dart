// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      backgroundColor: Colors.blue,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}