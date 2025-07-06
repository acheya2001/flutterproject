import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// 📝 Champ de texte personnalisé moderne
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final String? helperText;
  final Color? fillColor;
  final bool autofocus;

  const CustomTextField({
    Key? key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.helperText,
    this.fillColor,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _isFocused 
                  ? AppTheme.primaryColor 
                  : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Champ de texte
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.enabled ? AppTheme.textPrimary : AppTheme.textHint,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textHint,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused 
                        ? AppTheme.primaryColor 
                        : AppTheme.textSecondary,
                  )
                : null,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: widget.fillColor ?? 
                (widget.enabled 
                    ? (_isFocused 
                        ? AppTheme.primaryColor.withValues(alpha: 0.05)
                        : AppTheme.surfaceColor)
                    : AppTheme.surfaceColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
              borderSide: BorderSide(
                color: AppTheme.dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
              borderSide: BorderSide(
                color: AppTheme.dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignConstants.radiusM),
              borderSide: BorderSide(
                color: AppTheme.dividerColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.paddingM,
              vertical: DesignConstants.paddingM,
            ),
            counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
            ),
          ),
        ),
        
        // Texte d'aide
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
            ),
          ),
        ],
      ],
    );
  }
}

/// 📧 Champ email spécialisé
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool autofocus;

  const EmailTextField({
    Key? key,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Adresse email',
      hint: 'exemple@email.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      enabled: enabled,
      autofocus: autofocus,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // Pas d'espaces
      ],
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre adresse email';
    }
    if (!RegExp(ValidationConstants.emailRegex).hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }
    return null;
  }
}

/// 📱 Champ téléphone spécialisé
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const PhoneTextField({
    Key? key,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Numéro de téléphone',
      hint: '12345678',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: validator ?? _defaultPhoneValidator,
      onChanged: onChanged,
      enabled: enabled,
      maxLength: ValidationConstants.phoneLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(ValidationConstants.phoneLength),
      ],
    );
  }

  String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (!RegExp(ValidationConstants.phoneRegex).hasMatch(value)) {
      return 'Veuillez entrer un numéro de téléphone valide (8 chiffres)';
    }
    return null;
  }
}

/// 🆔 Champ CIN spécialisé
class CinTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const CinTextField({
    Key? key,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Numéro CIN',
      hint: '12345678',
      prefixIcon: Icons.badge_outlined,
      keyboardType: TextInputType.number,
      validator: validator ?? _defaultCinValidator,
      onChanged: onChanged,
      enabled: enabled,
      maxLength: ValidationConstants.cinLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(ValidationConstants.cinLength),
      ],
    );
  }

  String? _defaultCinValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro CIN';
    }
    if (!RegExp(ValidationConstants.cinRegex).hasMatch(value)) {
      return 'Veuillez entrer un numéro CIN valide (8 chiffres)';
    }
    return null;
  }
}

/// 🔒 Champ mot de passe spécialisé
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool showStrengthIndicator;

  const PasswordTextField({
    Key? key,
    this.controller,
    this.label = 'Mot de passe',
    this.hint = 'Entrez votre mot de passe',
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.showStrengthIndicator = false,
  }) : super(key: key);

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  PasswordStrength _strength = PasswordStrength.weak;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: widget.controller,
          label: widget.label,
          hint: widget.hint,
          prefixIcon: Icons.lock_outlined,
          obscureText: _obscureText,
          validator: widget.validator ?? _defaultPasswordValidator,
          onChanged: (value) {
            if (widget.showStrengthIndicator) {
              setState(() {
                _strength = _calculatePasswordStrength(value);
              });
            }
            widget.onChanged?.call(value);
          },
          enabled: widget.enabled,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            ),
          ),
        ),
        
        // Indicateur de force du mot de passe
        if (widget.showStrengthIndicator) ...[
          const SizedBox(height: 8),
          _buildPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _strength.value,
                backgroundColor: AppTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(_strength.color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _strength.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _strength.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _defaultPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < ValidationConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${ValidationConstants.minPasswordLength} caractères';
    }
    return null;
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    switch (score) {
      case 0:
      case 1:
        return PasswordStrength.weak;
      case 2:
      case 3:
        return PasswordStrength.medium;
      case 4:
      case 5:
        return PasswordStrength.strong;
      default:
        return PasswordStrength.weak;
    }
  }
}

/// 💪 Force du mot de passe
enum PasswordStrength {
  weak(0.33, AppTheme.errorColor, 'Faible'),
  medium(0.66, AppTheme.warningColor, 'Moyen'),
  strong(1.0, AppTheme.accentColor, 'Fort');

  const PasswordStrength(this.value, this.color, this.label);

  final double value;
  final Color color;
  final String label;
}
