import 'package:flutter/material.dart';
import 'package:constat_tunisie/presentation/screens/auth/login_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(toggleView: _toggleView);
    } else {
      return RegisterScreen(toggleView: _toggleView);
    }
  }
}
