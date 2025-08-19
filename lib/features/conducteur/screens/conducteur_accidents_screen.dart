import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';

class ConducteurAccidentsScreen extends StatefulWidget {
  const ConducteurAccidentsScreen({super.key});

  @override
  State<ConducteurAccidentsScreen> createState() => _ConducteurAccidentsScreenState();
}

class _ConducteurAccidentsScreenState extends State<ConducteurAccidentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes Accidents',
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.car_crash_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun accident déclaré',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vos déclarations d\'accidents apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
