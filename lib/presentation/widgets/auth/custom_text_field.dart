import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key, // Utilisation de super.key
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.contentPadding,
    this.suffixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autofocus,
      style: TextStyle(
        color: AppTheme.darkColor, // Utilisation de la couleur ajoutée
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: Icon(
          widget.prefixIcon,
          color: Colors.grey.withAlpha(200), // Remplacé withOpacity par withAlpha
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.greyColor, // Utilisation de la couleur ajoutée
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.lightGreyColor, // Utilisation de la couleur ajoutée
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
      ),
    );
  }
}
