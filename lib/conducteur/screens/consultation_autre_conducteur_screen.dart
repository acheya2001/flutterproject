import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/accident_session_complete.dart';
import '../../services/accident_session_complete_service.dart';

/// 👁️ Écran de consultation de la partie de l'autre conducteur
class ConsultationAutreConducteurScreen extends StatefulWidget {
  final AccidentSessionComplete session;

  const ConsultationAutreConducteurScreen({
    super.key,
    required this.session,
  });

  @override
  State<ConsultationAutreConducteurScreen> createState() => _ConsultationAutreConducteurScreenState();
}

class _ConsultationAutreConducteurScreenState extends State<ConsultationAutreConducteurScreen> {
  bool _isLoading = true;
  AccidentSessionComplete? _sessionActualisee;
  String? _monUserId;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      // Récupérer l'utilisateur actuel
      final user = FirebaseAuth.instance.currentUser;
      _monUserId = user?.uid;

      // Récupérer la session actualisée
      final session = await AccidentSessionCompleteService.obtenirSession(widget.session.id);
      
      setState(() {
        _sessionActualisee = session;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Consultation croisée',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _chargerDonnees,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessionActualisee == null
              ? _buildErreur()
              : _buildContenu(),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Impossible de charger les données',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'Vérifiez votre connexion internet et réessayez.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _chargerDonnees,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu() {
    final autresConducteurs = _sessionActualisee!.conducteurs
        .where((c) => c.userId != _monUserId)
        .toList();

    if (autresConducteurs.isEmpty) {
      return _buildAucunAutreConducteur();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildEnTete(),
          
          const SizedBox(height: 24),
          
          // Liste des autres conducteurs
          ...autresConducteurs.map((conducteur) => _buildCarteConducteur(conducteur)).toList(),
        ],
      ),
    );
  }

  Widget _buildEnTete() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo[600]!,
            Colors.indigo[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation croisée',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Consultez les informations des autres conducteurs',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Session: ${_sessionActualisee!.codeSession}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAucunAutreConducteur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Aucun autre conducteur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'Aucun autre conducteur n\'a encore rejoint cette session. Partagez le code de session pour qu\'ils puissent participer.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Partager le code de session
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Code de session: ${_sessionActualisee!.codeSession}'),
                    action: SnackBarAction(
                      label: 'Copier',
                      onPressed: () {
                        // TODO: Copier dans le presse-papiers
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Partager le code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteConducteur(ConducteurSession conducteur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du conducteur
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conducteur.nom ?? 'Conducteur ${conducteur.roleVehicule}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Véhicule ${conducteur.roleVehicule}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatutColor(conducteur.statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatutText(conducteur.statut),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatutColor(conducteur.statut),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations disponibles
          if (conducteur.informationsRemplies.isNotEmpty) ...[
            const Text(
              'Informations remplies :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conducteur.informationsRemplies.map((info) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    info,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orange[600], size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Aucune information remplie pour le moment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Bouton pour voir les détails
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: conducteur.informationsRemplies.isNotEmpty
                  ? () => _voirDetailsConducteur(conducteur)
                  : null,
              icon: const Icon(Icons.visibility),
              label: const Text('Voir les détails'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo[600],
                side: BorderSide(color: Colors.indigo[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'connecte':
        return Colors.green;
      case 'en_cours':
        return Colors.orange;
      case 'termine':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'connecte':
        return 'Connecté';
      case 'en_cours':
        return 'En cours';
      case 'termine':
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  void _voirDetailsConducteur(ConducteurSession conducteur) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Poignée
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Contenu
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails - ${conducteur.nom ?? 'Conducteur ${conducteur.roleVehicule}'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // TODO: Afficher les détails du conducteur
                        const Text(
                          'Fonctionnalité en cours de développement.\n\n'
                          'Ici seront affichées toutes les informations remplies par l\'autre conducteur :\n'
                          '• Informations du véhicule\n'
                          '• Informations d\'assurance\n'
                          '• Description de l\'accident\n'
                          '• Photos des dégâts\n'
                          '• Croquis et annotations',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
