import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../widgets/contract_documents_widget.dart';
import 'my_contracts_screen.dart';

/// 🎉 Écran de confirmation de validation de contrat
class ContractValidatedScreen extends StatefulWidget {
  final Map<String, dynamic> contractData;
  final Map<String, String>? documents;

  const ContractValidatedScreen({
    Key? key,
    required this.contractData,
    this.documents,
  }) : super(key: key);

  @override
  State<ContractValidatedScreen> createState() => _ContractValidatedScreenState();
}

class _ContractValidatedScreenState extends State<ContractValidatedScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Animation de succès
              _buildSuccessAnimation(),
              
              const SizedBox(height: 30),
              
              // Message de félicitations
              _buildCongratulationsMessage(),
              
              const SizedBox(height: 30),
              
              // Informations du contrat
              _buildContractSummary(),
              
              const SizedBox(height: 30),
              
              // Documents disponibles
              FadeTransition(
                opacity: _fadeAnimation,
                child: ContractDocumentsWidget(
                  contractId: widget.contractData['id'] ?? '',
                  contractData: widget.contractData,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Boutons d'action
              _buildActionButtons(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎊 Animation de succès
  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 🎉 Message de félicitations
  Widget _buildCongratulationsMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            '🎉 Félicitations !',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Votre contrat d\'assurance a été validé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade300,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Votre véhicule est maintenant protégé',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📋 Résumé du contrat
  Widget _buildContractSummary() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF334155),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.shade400.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Détails du Contrat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Informations
            _buildInfoRow('N° Contrat', widget.contractData['numeroContrat'] ?? ''),
            _buildInfoRow('Véhicule', widget.contractData['vehiculeInfo']?['immatriculation'] ?? ''),
            _buildInfoRow('Type d\'assurance', widget.contractData['typeContratDisplay'] ?? widget.contractData['typeContrat'] ?? ''),
            _buildInfoRow('Prime annuelle', '${widget.contractData['primeAnnuelle'] ?? 0} DT'),
            _buildInfoRow('Validité', '${_formatDate(widget.contractData['dateDebut'])} - ${_formatDate(widget.contractData['dateFin'])}'),
          ],
        ),
      ),
    );
  }

  /// 📊 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToMyContracts(),
              icon: const Icon(Icons.description_rounded),
              label: const Text('Voir Mes Contrats'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: Colors.green.withOpacity(0.3),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bouton secondaire
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToHome(),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Retour à l\'Accueil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Naviguer vers mes contrats
  void _navigateToMyContracts() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyContractsScreen(),
      ),
    );
  }

  /// 🏠 Naviguer vers l'accueil
  void _navigateToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = (date as Timestamp).toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return date.toString();
    }
    
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}
