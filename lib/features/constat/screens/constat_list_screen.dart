import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Non utilisé actuellement
// import '../../constat/providers/session_provider.dart'; // Non utilisé actuellement
// import 'conducteur_declaration_screen.dart'; // Non utilisé actuellement
import '../../../core/widgets/custom_app_bar.dart';

class ConstatListScreen extends StatelessWidget {
  const ConstatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Mes Constats'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Liste de vos constats (à implémenter)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Exemple: Naviguer pour créer une nouvelle session ou en rejoindre une
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SessionSetupScreen()));
                // ou
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SessionJoinScreen()));
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigation vers la création de constat à implémenter.')),
                );
              },
              child: const Text('Nouveau Constat'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                // La logique pour rejoindre une session via un code devrait être gérée
                // par un écran dédié comme SessionJoinScreen.
                // Si vous voulez naviguer vers cet écran:
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SessionJoinScreen()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logique "Rejoindre via code" à implémenter ici ou via un autre écran.')),
                );
              },
              child: const Text('Rejoindre via code (placeholder)'),
            )
          ],
        ),
      ),
    );
  }
}
