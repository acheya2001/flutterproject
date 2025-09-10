import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/vehicule_management_service.dart';

class AddVehicleScreen extends StatefulWidget {
  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _anneeController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un Véhicule'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _marqueController,
                      decoration: InputDecoration(labelText: 'Marque'),
                      validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                    ),
                    TextFormField(
                      controller: _modeleController,
                      decoration: InputDecoration(labelText: 'Modèle'),
                      validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                    ),
                    TextFormField(
                      controller: _immatriculationController,
                      decoration: InputDecoration(labelText: 'Immatriculation'),
                      validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                    ),
                    TextFormField(
                      controller: _anneeController,
                      decoration: InputDecoration(labelText: 'Année'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Champ requis';
                        final year = int.tryParse(value);
                        if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                          return 'Année invalide';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitVehicle,
                      child: Text('Soumettre'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitVehicle() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) setState(() {
        _isLoading = true;
      });

      try {
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }

        await VehiculeManagementService.addVehicle({
          'marque': _marqueController.text,
          'modele': _modeleController.text,
          'immatriculation': _immatriculationController.text,
          'annee': int.parse(_anneeController.text),
          'conducteurId': user.uid,
        });
        Navigator.pop(context);
      } catch (e) {
        // Gérer l'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout du véhicule: $e')),
        );
      } finally {
        if (mounted) setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

