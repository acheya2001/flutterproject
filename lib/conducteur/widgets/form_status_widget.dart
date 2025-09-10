import 'package:flutter/material.dart';
import '../../services/form_status_service.dart';

/// 📊 Widget d'affichage des états des formulaires
class FormStatusWidget extends StatefulWidget {
  final String sessionId;
  final VoidCallback? onFormTap;

  const FormStatusWidget({
    Key? key,
    required this.sessionId,
    this.onFormTap,
  }) : super(key: key);

  @override
  State<FormStatusWidget> createState() => _FormStatusWidgetState();
}

class _FormStatusWidgetState extends State<FormStatusWidget> {
  List<FormStatusInfo> _etatsFormulaires = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {

    // Utiliser addPostFrameCallback pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerEtatsFormulaires();
    });
    });
  }

  Future<void> _chargerEtatsFormulaires() async {
    setState(() => _isLoading = true);
    
    final etats = await FormStatusService.obtenirEtatsFormulaires(
      sessionId: widget.sessionId,
    );
    
    if (mounted) setState(() {
      _etatsFormulaires = etats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Mes Formulaires',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _chargerEtatsFormulaires,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ),

          // Contenu
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_etatsFormulaires.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun formulaire commencé',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez à remplir un formulaire pour le voir apparaître ici',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Statistiques globales
                  _buildStatistiquesGlobales(),
                  const SizedBox(height: 16),
                  
                  // Liste des formulaires
                  ..._etatsFormulaires.map((etat) => _buildFormulaireCard(etat)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 📊 Widget des statistiques globales
  Widget _buildStatistiquesGlobales() {
    final int total = _etatsFormulaires.length;
    final int termines = _etatsFormulaires.where((e) => e.statut == FormStatus.termine).length;
    final int enCours = _etatsFormulaires.where((e) => e.statut == FormStatus.enCours).length;
    final int enAttente = _etatsFormulaires.where((e) => e.statut == FormStatus.enAttente).length;
    
    final double progression = total > 0 ? (termines / total) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progression Globale',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${progression.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: progression == 100 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progression / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progression == 100 ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🔴', 'En attente', enAttente),
              _buildStatItem('🟡', 'En cours', enCours),
              _buildStatItem('🟢', 'Terminé', termines),
            ],
          ),
        ],
      ),
    );
  }

  /// 📈 Widget d'un élément de statistique
  Widget _buildStatItem(String emoji, String label, int count) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 📋 Widget d'une carte de formulaire
  Widget _buildFormulaireCard(FormStatusInfo etat) {
    final couleur = FormStatusInfo.getCouleurStatut(etat.statut);
    final texte = FormStatusInfo.getTexteStatut(etat.statut);
    final icone = FormStatusInfo.getIconeStatut(etat.statut);
    final nom = FormStatusService.getNomEtape(etat.etape);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: couleur.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onFormTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône de statut
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icone,
                  color: couleur,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: couleur,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            texte,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (etat.statut == FormStatus.enCours) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${etat.pourcentageCompletion.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (etat.dateModification != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Modifié le ${_formatDate(etat.dateModification!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

