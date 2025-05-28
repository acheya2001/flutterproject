import 'package:flutter/material.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';

class ConstatListScreen extends StatelessWidget {
  const ConstatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Historique des constats',
      ),
      body: const EmptyState(
        icon: Icons.description_outlined,
        title: 'Aucun constat',
        message: 'Vous n\'avez pas encore créé de constat d\'accident.',
      ),
    );
  }
}
