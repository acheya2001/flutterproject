import 'package:flutter/material.dart';
import 'package:constat_tunisie/presentation/screens/auth/login_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/register_screen.dart';
import 'package:logger/logger.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final Logger _logger = Logger();
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
      _logger.i("Vue basculée vers: ${_showLogin ? 'Login' : 'Register'}");
    });
  }

  @override
  void initState() {
    super.initState();
    _logger.i("AuthScreen initialisé");
  }

  @override
  Widget build(BuildContext context) {
    _logger.d("Construction de AuthScreen, affichage: ${_showLogin ? 'Login' : 'Register'}");
    
    if (_showLogin) {
      return LoginScreen(toggleView: _toggleView);
    } else {
      return RegisterScreen(toggleView: _toggleView);
    }
  }
}