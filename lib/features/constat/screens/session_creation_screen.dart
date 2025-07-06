import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../../vehicule/models/vehicule_model.dart'; // Assurez-vous que ce chemin est correct
import '../../../core/services/session_service.dart';
import '../../../core/services/email_service.dart';

// CORRECTION: Changed _SessionCreationScreenState to public
class SessionCreationScreen extends ConsumerStatefulWidget {
  const SessionCreationScreen({Key? key}) : super(key: key);

  @override
  SessionCreationScreenState createState() => SessionCreationScreenState();
}

// CORRECTION: Changed _SessionCreationScreenState to public
class SessionCreationScreenState extends ConsumerState<SessionCreationScreen> {
  int _nombreVehiculesInput = 2;
  bool _isOwnerOfInitiatingVehicle = false; 
  VehiculeModel? _selectedVehiculeForInitiator;
  List<TextEditingController> _emailControllers = [];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      int initialCountFromArgs = arguments['initiatingVehicleCount'] as int? ?? 2;
      _nombreVehiculesInput = initialCountFromArgs == 1 ? 1 : 2;
      _isOwnerOfInitiatingVehicle = arguments['isOwnerOfInitiatingVehicle'] as bool? ?? false;
      _setupEmailControllers();
    }
  }

  void _setupEmailControllers() {
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    _emailControllers = List.generate(
        _nombreVehiculesInput > 1 ? _nombreVehiculesInput - 1 : 0, 
        (_) => TextEditingController()
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectInitiatorVehicle() async {
    if (!mounted) return;
    final authProviderInstance = ref.read(authProvider);
    // CORRECTION: Ensure currentUser and its id are not null before using.
    final String? currentUserId = authProviderInstance.currentUser?.id;
    if (currentUserId == null) {
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilisateur non connecté.")));
        }
        return;
    }

    final selected = await Navigator.pushNamed(
      context,
      AppRoutes.conducteurVehicules,
      arguments: {'selectionMode': true, 'conducteurId': currentUserId},
    );

    if (selected != null && selected is VehiculeModel) {
      setState(() {
        _selectedVehiculeForInitiator = selected;
      });
    }
  }

  Future<void> _creerSession() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProviderInstance = ref.read(authProvider);
    final sessionProvider = SessionProvider(
      sessionService: SessionService(),
    );

    if (authProviderInstance.currentUser == null || authProviderInstance.currentUser!.id.isEmpty) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilisateur non connecté.")));
      }
      setState(() => _isLoading = false);
      return;
    }

    if (_isOwnerOfInitiatingVehicle && _selectedVehiculeForInitiator == null) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner votre véhicule.")));
      }
      setState(() => _isLoading = false);
      return;
    }
    
    List<String> emailsInvites = _emailControllers
        .map((controller) => controller.text.trim())
        .where((email) => email.isNotEmpty && RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email))
        .toList();
    
    if (_nombreVehiculesInput > 1 && emailsInvites.length != _nombreVehiculesInput -1) {
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veuillez fournir ${_nombreVehiculesInput -1} adresses email valides.")));
        }
        setState(() => _isLoading = false);
        return;
    }

    try {
      // CORRECTION: Ensure creerSession returns String, not String? or handle nullability
      final String? newSessionId = await sessionProvider.creerSession(
        nombreConducteurs: _nombreVehiculesInput,
        emailsInvites: emailsInvites,
        createdBy: authProviderInstance.currentUser!.id, // currentUser is checked above
        dateAccident: DateTime.now(), 
        lieuAccident: "Lieu à définir par l'initiateur", 
      );

      if (newSessionId == null) {
        throw Exception("La création de session a échoué (ID nul retourné).");
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.conducteurDeclaration,
          arguments: {
            'sessionId': newSessionId, // Now newSessionId is confirmed not null
            'conducteurPosition': 'A', 
            'isCollaborative': true,
            'selectedVehicule': _selectedVehiculeForInitiator, 
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur création session: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une Session Collaborative')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _nombreVehiculesInput.toString(),
                decoration: const InputDecoration(
                  labelText: 'Nombre total de véhicules impliqués',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  final n = int.tryParse(value);
                  if (n == null || n < 2) return 'Minimum 2 véhicules pour une session';
                  return null;
                },
                onChanged: (value) {
                  final n = int.tryParse(value);
                  if (n != null && n >= 2) {
                    setState(() {
                      _nombreVehiculesInput = n;
                      _setupEmailControllers();
                    });
                  } else if (n != null && n < 2) {
                     setState(() {
                      _nombreVehiculesInput = 2;
                      _setupEmailControllers();
                    });
                  }
                },
              ),
              if (_isOwnerOfInitiatingVehicle) ...[
                const SizedBox(height: 16),
                Text('Votre véhicule (initiateur):', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_selectedVehiculeForInitiator != null)
                  Card(
                    child: ListTile(
                      title: Text('${_selectedVehiculeForInitiator!.marque} ${_selectedVehiculeForInitiator!.modele}'),
                      subtitle: Text(_selectedVehiculeForInitiator!.immatriculation),
                      trailing: IconButton(icon: const Icon(Icons.edit), onPressed: _selectInitiatorVehicle),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Sélectionner votre véhicule'),
                    onPressed: _selectInitiatorVehicle,
                  ),
              ],
              const SizedBox(height: 24),
              if (_nombreVehiculesInput > 1) ...[
                Text('Inviter les autres conducteurs (${_nombreVehiculesInput - 1}) par email:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_emailControllers.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _emailControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: TextFormField(
                          controller: _emailControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Email Conducteur ${String.fromCharCode('B'.codeUnitAt(0) + index)}',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email requis';
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Email invalide';
                            return null;
                          },
                        ),
                      );
                    },
                  )
                else
                  const Text("Aucun autre conducteur à inviter pour le moment."),
              ],
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.group_add),
                    label: const Text('Créer la session et inviter'),
                    onPressed: _creerSession,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}