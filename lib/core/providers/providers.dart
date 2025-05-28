// lib/core/providers/providers.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import 'theme_provider.dart';

class Providers {
  static final providers = [
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
    ),
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
    ),
  ];
}