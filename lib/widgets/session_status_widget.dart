import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/accident_session_complete.dart';
import '../services/accident_session_complete_service.dart';

/// 📊 Widget pour afficher le statut d'une session en temps réel
class SessionStatusWidget extends StatelessWidget {
  final String sessionId;
  final bool showDetails;
  final VoidCallback? onTap;

  const SessionStatusWidget({
    super.key,
    required this.sessionId,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AccidentSessionComplete?>(
      stream: AccidentSessionCompleteService.ecouterSession(sessionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        final session = snapshot.data;
        if (session == null) {
          return _buildNotFoundWidget();
        }

        return _buildSessionCard(context, session);
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, AccidentSessionComplete session) {
    final statutColor = _getStatutColor(session.statut);
    final statutIcon = _getStatutIcon(session.statut);
    final pourcentageCompletion = _calculateCompletion(session);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(statutIcon, color: statutColor, size: 20),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session ${session.codeSession}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getStatutText(session.statut),
                          style: TextStyle(
                            fontSize: 14,
                            color: statutColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${session.conducteurs.length}/${session.nombreVehicules}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statutColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (showDetails) ...[
                const SizedBox(height: 16),
                
                // Barre de progression
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progression',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$pourcentageCompletion%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statutColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    LinearProgressIndicator(
                      value: pourcentageCompletion / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statutColor),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Informations détaillées
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.access_time,
                        'Créé',
                        _formatDate(session.dateCreation),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.location_on,
                        'Lieu',
                        session.infosGenerales.lieuAccident.isNotEmpty 
                            ? session.infosGenerales.lieuAccident.substring(0, 
                                session.infosGenerales.lieuAccident.length > 15 ? 15 : session.infosGenerales.lieuAccident.length)
                            : 'Non défini',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement de la session...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erreur: $error',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.search_off, color: Colors.grey[600]),
            const SizedBox(width: 12),
            const Text('Session non trouvée'),
          ],
        ),
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'creation':
      case 'en_attente':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'signe':
      case 'termine':
        return Colors.green;
      case 'annule':
      case 'expire':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut.toLowerCase()) {
      case 'creation':
        return Icons.add_circle_outline;
      case 'en_attente':
        return Icons.hourglass_empty;
      case 'en_cours':
        return Icons.play_circle_outline;
      case 'signe':
        return Icons.check_circle_outline;
      case 'termine':
        return Icons.check_circle;
      case 'annule':
        return Icons.cancel_outlined;
      case 'expire':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatutText(String statut) {
    switch (statut.toLowerCase()) {
      case 'creation':
        return 'En création';
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'signe':
        return 'Signé';
      case 'termine':
        return 'Terminé';
      case 'annule':
        return 'Annulé';
      case 'expire':
        return 'Expiré';
      default:
        return 'Inconnu';
    }
  }

  int _calculateCompletion(AccidentSessionComplete session) {
    int etapesCompletes = 0;
    int etapesTotales = 6;
    
    if (session.infosGenerales.lieuAccident.isNotEmpty) etapesCompletes++;
    if (session.vehicules.isNotEmpty) etapesCompletes++;
    if (session.circonstances.circonstancesParVehicule.isNotEmpty) etapesCompletes++;
    if (session.croquis.croquisData.isNotEmpty) etapesCompletes++;
    if (session.signatures.isNotEmpty) etapesCompletes++;
    if (session.photos.isNotEmpty) etapesCompletes++;

    return (etapesCompletes / etapesTotales * 100).round();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
