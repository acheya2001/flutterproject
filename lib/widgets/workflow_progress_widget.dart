import 'package:flutter/material.dart';

/// 📊 Widget pour afficher la progression du workflow
class WorkflowProgressWidget extends StatelessWidget {
  final int etapeActuelle;
  final int etapesTotales;
  final List<String> nomsEtapes;
  final List<bool> etapesCompletes;
  final Color? couleurPrimaire;
  final bool showLabels;
  final bool isVertical;

  const WorkflowProgressWidget({
    super.key,
    required this.etapeActuelle,
    required this.etapesTotales,
    required this.nomsEtapes,
    required this.etapesCompletes,
    this.couleurPrimaire,
    this.showLabels = true,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = couleurPrimaire ?? Theme.of(context).primaryColor;
    
    return isVertical ? _buildVerticalProgress(couleur) : _buildHorizontalProgress(couleur);
  }

  Widget _buildHorizontalProgress(Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de progression principale
          Row(
            children: List.generate(etapesTotales, (index) {
              final estComplete = etapesCompletes.length > index ? etapesCompletes[index] : false;
              final estActuelle = index == etapeActuelle;
              final estAccessible = index <= etapeActuelle;
              
              return Expanded(
                child: Row(
                  children: [
                    // Cercle d'étape
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: estComplete 
                            ? couleur 
                            : estActuelle 
                                ? couleur.withOpacity(0.7)
                                : estAccessible
                                    ? couleur.withOpacity(0.3)
                                    : Colors.grey[300],
                        border: Border.all(
                          color: estActuelle ? couleur : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: estComplete
                            ? Icon(Icons.check, color: Colors.white, size: 18)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: estAccessible ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    
                    // Ligne de connexion (sauf pour la dernière étape)
                    if (index < etapesTotales - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: etapesCompletes.length > index + 1 && etapesCompletes[index + 1]
                              ? couleur
                              : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          
          if (showLabels) ...[
            const SizedBox(height: 12),
            
            // Labels des étapes
            Row(
              children: List.generate(etapesTotales, (index) {
                final estComplete = etapesCompletes.length > index ? etapesCompletes[index] : false;
                final estActuelle = index == etapeActuelle;
                final nom = nomsEtapes.length > index ? nomsEtapes[index] : 'Étape ${index + 1}';
                
                return Expanded(
                  child: Text(
                    nom,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: estActuelle ? FontWeight.bold : FontWeight.normal,
                      color: estComplete || estActuelle ? couleur : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalProgress(Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(etapesTotales, (index) {
          final estComplete = etapesCompletes.length > index ? etapesCompletes[index] : false;
          final estActuelle = index == etapeActuelle;
          final estAccessible = index <= etapeActuelle;
          final nom = nomsEtapes.length > index ? nomsEtapes[index] : 'Étape ${index + 1}';
          
          return Column(
            children: [
              Row(
                children: [
                  // Cercle d'étape
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: estComplete 
                          ? couleur 
                          : estActuelle 
                              ? couleur.withOpacity(0.7)
                              : estAccessible
                                  ? couleur.withOpacity(0.3)
                                  : Colors.grey[300],
                      border: Border.all(
                        color: estActuelle ? couleur : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: estComplete
                          ? Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: estAccessible ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Label de l'étape
                  if (showLabels)
                    Expanded(
                      child: Text(
                        nom,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: estActuelle ? FontWeight.bold : FontWeight.normal,
                          color: estComplete || estActuelle ? couleur : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
              
              // Ligne de connexion (sauf pour la dernière étape)
              if (index < etapesTotales - 1)
                Container(
                  margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                  width: 2,
                  height: 24,
                  color: etapesCompletes.length > index + 1 && etapesCompletes[index + 1]
                      ? couleur
                      : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// 🎯 Widget pour afficher un résumé de progression
class ProgressSummaryWidget extends StatelessWidget {
  final int etapesCompletes;
  final int etapesTotales;
  final String? titre;
  final Color? couleur;
  final List<String>? prochaines;

  const ProgressSummaryWidget({
    super.key,
    required this.etapesCompletes,
    required this.etapesTotales,
    this.titre,
    this.couleur,
    this.prochaines,
  });

  @override
  Widget build(BuildContext context) {
    final couleurPrimaire = couleur ?? Theme.of(context).primaryColor;
    final pourcentage = (etapesCompletes / etapesTotales * 100).round();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.trending_up, color: couleurPrimaire),
                const SizedBox(width: 8),
                Text(
                  titre ?? 'Progression',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: couleurPrimaire.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pourcentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: couleurPrimaire,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$etapesCompletes sur $etapesTotales étapes',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                LinearProgressIndicator(
                  value: etapesCompletes / etapesTotales,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(couleurPrimaire),
                  minHeight: 8,
                ),
              ],
            ),
            
            // Prochaines étapes
            if (prochaines != null && prochaines!.isNotEmpty) ...[
              const SizedBox(height: 16),
              
              const Text(
                'Prochaines étapes :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              ...prochaines!.take(3).map((etape) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        etape,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
