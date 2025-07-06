import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionInvitationCard extends StatelessWidget {
  final String sessionCode;
  final String sessionId;
  final DateTime dateAccident;
  final String lieuAccident;
  final int nombreConducteurs;
  final int conducteursRejoints;
  final VoidCallback onJoin;
  final VoidCallback? onShare;

  const SessionInvitationCard({
    Key? key,
    required this.sessionCode,
    required this.sessionId,
    required this.dateAccident,
    required this.lieuAccident,
    required this.nombreConducteurs,
    required this.conducteursRejoints,
    required this.onJoin,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = conducteursRejoints / nombreConducteurs;
    final isComplete = conducteursRejoints == nombreConducteurs;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isComplete 
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onJoin,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec code et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Code de session
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.vpn_key,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sessionCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Actions
                    Row(
                      children: [
                        // Bouton copier
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: sessionCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Code $sessionCode copié'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        
                        // Bouton partager
                        if (onShare != null)
                          IconButton(
                            onPressed: onShare,
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Informations de l'accident
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lieuAccident,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(dateAccident),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Progression des conducteurs
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Conducteurs',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$conducteursRejoints/$nombreConducteurs',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Barre de progression
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Bouton d'action
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isComplete ? Icons.check_circle : Icons.login,
                            color: isComplete ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isComplete ? 'Terminé' : 'Rejoindre',
                            style: TextStyle(
                              color: isComplete ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
