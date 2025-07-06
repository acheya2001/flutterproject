import 'package:flutter/material.dart';
import '../../models/professional_request_model_final.dart';
import '../../../../core/theme/modern_theme.dart';
import '../../services/professional_request_management_service.dart';
import '../../../../core/services/approval_email_service.dart';

/// 📋 Modal de détails d'une demande professionnelle
class RequestDetailsModal extends StatefulWidget {
  final ProfessionalRequestModel request;
  final VoidCallback onRequestUpdated;

  const RequestDetailsModal({
    super.key,
    required this.request,
    required this.onRequestUpdated,
  });

  @override
  State<RequestDetailsModal> createState() => _RequestDetailsModalState();
}

class _RequestDetailsModalState extends State<RequestDetailsModal> {
  final TextEditingController _commentController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            _buildHeader(),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequestInfo(),
                    const SizedBox(height: 24),
                    _buildPersonalInfo(),
                    const SizedBox(height: 24),
                    _buildProfessionalInfo(),
                    if (widget.request.status == 'en_attente') ...[
                      const SizedBox(height: 24),
                      _buildCommentField(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            if (widget.request.status == 'en_attente')
              _buildActionButtons()
            else
              _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détails - ${widget.request.nomComplet}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ModernTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Informations complètes de la demande',
                  style: TextStyle(
                    fontSize: 14,
                    color: ModernTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestInfo() {
    return _buildSection(
      title: 'Informations de la demande',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow('Statut', _getStatusText(), color: _getStatusColor()),
        _buildInfoRow('Rôle demandé', _getRoleText()),
        _buildInfoRow('Date de soumission', _formatDate(widget.request.envoyeLe)),
        if (widget.request.traiteLe != null)
          _buildInfoRow('Date de traitement', _formatDate(widget.request.traiteLe!)),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      title: 'Informations personnelles',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow('Nom complet', widget.request.nomComplet),
        _buildInfoRow('Email', widget.request.email),
        _buildInfoRow('Téléphone', widget.request.tel),
        _buildInfoRow('CIN', widget.request.cin),
      ],
    );
  }

  Widget _buildProfessionalInfo() {
    final role = widget.request.roleDemande;
    
    return _buildSection(
      title: 'Informations professionnelles',
      icon: Icons.work_outline,
      children: _getProfessionalFields(role),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: ModernTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ModernTheme.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? ModernTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commentaire (optionnel)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ModernTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ajoutez un commentaire...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ModernTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _handleAction('rejetee'),
              icon: const Icon(Icons.close),
              label: const Text('Rejeter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _handleAction('acceptee'),
              icon: const Icon(Icons.check),
              label: const Text('Approuver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildCloseButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          label: const Text('Fermer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ModernTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires
  Color _getStatusColor() {
    switch (widget.request.status) {
      case 'acceptee': return Colors.green;
      case 'rejetee': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.request.status) {
      case 'acceptee': return Icons.check_circle;
      case 'rejetee': return Icons.cancel;
      default: return Icons.pending;
    }
  }

  String _getStatusText() {
    switch (widget.request.status) {
      case 'acceptee': return 'Approuvée';
      case 'rejetee': return 'Rejetée';
      default: return 'En attente';
    }
  }

  String _getRoleText() {
    switch (widget.request.roleDemande) {
      case 'agent_agence': return 'Agent d\'Agence';
      case 'expert_auto': return 'Expert Automobile';
      case 'admin_compagnie': return 'Admin Compagnie';
      case 'admin_agence': return 'Admin Agence';
      default: return widget.request.roleDemande;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<Widget> _getProfessionalFields(String role) {
    switch (role) {
      case 'agent_agence':
        return [
          if (widget.request.nomAgence != null)
            _buildInfoRow('Nom agence', widget.request.nomAgence!),
          if (widget.request.compagnie != null)
            _buildInfoRow('Compagnie', widget.request.compagnie!),
          if (widget.request.adresseAgence != null)
            _buildInfoRow('Adresse agence', widget.request.adresseAgence!),
          if (widget.request.matriculeInterne != null)
            _buildInfoRow('Matricule', widget.request.matriculeInterne!),
        ];
      case 'expert_auto':
        return [
          if (widget.request.numAgrement != null)
            _buildInfoRow('N° Agrément', widget.request.numAgrement!),
          if (widget.request.zoneIntervention != null)
            _buildInfoRow('Zone intervention', widget.request.zoneIntervention!),
          if (widget.request.experienceAnnees != null)
            _buildInfoRow('Expérience', '${widget.request.experienceAnnees} ans'),
        ];
      case 'admin_compagnie':
        return [
          if (widget.request.nomCompagnie != null)
            _buildInfoRow('Nom compagnie', widget.request.nomCompagnie!),
          if (widget.request.fonction != null)
            _buildInfoRow('Fonction', widget.request.fonction!),
          if (widget.request.adresseSiege != null)
            _buildInfoRow('Adresse siège', widget.request.adresseSiege!),
          if (widget.request.numAutorisation != null)
            _buildInfoRow('N° Autorisation', widget.request.numAutorisation!),
        ];
      case 'admin_agence':
        return [
          if (widget.request.nomAgence != null)
            _buildInfoRow('Nom agence', widget.request.nomAgence!),
          if (widget.request.ville != null)
            _buildInfoRow('Ville', widget.request.ville!),
          if (widget.request.telAgence != null)
            _buildInfoRow('Tél. agence', widget.request.telAgence!),
        ];
      default:
        return [const Text('Aucune information spécifique')];
    }
  }

  Future<void> _handleAction(String newStatus) async {
    setState(() => _isProcessing = true);

    try {
      bool success = false;

      if (newStatus == 'acceptee') {
        success = await ProfessionalRequestManagementService.approveRequest(
          requestId: widget.request.id,
          adminId: 'super_admin', // TODO: Récupérer l'ID de l'admin connecté
          commentaire: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
        );
      } else if (newStatus == 'rejetee') {
        success = await ProfessionalRequestManagementService.rejectRequest(
          requestId: widget.request.id,
          adminId: 'super_admin', // TODO: Récupérer l'ID de l'admin connecté
          motifRejet: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : 'Votre demande ne répond pas aux critères requis.',
          commentaire: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
        );
      }

      if (success) {
        // Envoyer l'email de notification
        if (newStatus == 'acceptee') {
          await ApprovalEmailService.sendApprovalEmail(
            toEmail: widget.request.email,
            nomComplet: widget.request.nomComplet,
            role: widget.request.roleDemande,
            motDePasseTemporaire: 'TempPass123!', // Mot de passe temporaire
          );
        } else if (newStatus == 'rejetee') {
          await ApprovalEmailService.sendRejectionEmail(
            toEmail: widget.request.email,
            nomComplet: widget.request.nomComplet,
            role: widget.request.roleDemande,
            motifRejet: _commentController.text.trim().isNotEmpty
                ? _commentController.text.trim()
                : 'Votre demande ne répond pas aux critères requis.',
          );
        }

        if (mounted) {
          widget.onRequestUpdated();
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == 'acceptee' 
                    ? 'Demande approuvée avec succès !' 
                    : 'Demande rejetée.',
              ),
              backgroundColor: newStatus == 'acceptee' ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
