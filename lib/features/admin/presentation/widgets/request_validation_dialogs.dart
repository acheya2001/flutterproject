import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_theme.dart';
import '../../models/professional_request_model_final.dart';
import '../providers/professional_requests_provider.dart';

/// ✅ Dialogue de confirmation d'approbation
class ApprovalDialog extends ConsumerStatefulWidget {
  final ProfessionalRequestModel request;
  final String adminId;

  const ApprovalDialog({
    super.key,
    required this.request,
    required this.adminId,
  });

  @override
  ConsumerState<ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<ApprovalDialog> {
  final TextEditingController _commentController = TextEditingController();
  bool _createAccount = true;
  bool _sendNotification = true;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionsState = ref.watch(requestActionsProvider);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.check_circle,
              color: ModernTheme.successColor,
              size: 24,
            ),
          ),
          const SizedBox(width: ModernTheme.spacingM),
          const Expanded(
            child: Text(
              'Approuver la demande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du demandeur
            _buildRequestInfo(),
            
            const SizedBox(height: ModernTheme.spacingL),
            
            // Options d'approbation
            _buildApprovalOptions(),
            
            const SizedBox(height: ModernTheme.spacingM),
            
            // Commentaire optionnel
            _buildCommentField(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: actionsState.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: actionsState.isLoading ? null : _handleApproval,
          icon: actionsState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Approuver'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ModernTheme.successColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 📋 Informations de la demande
  Widget _buildRequestInfo() {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: BoxDecoration(
        color: ModernTheme.successColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: ModernTheme.successColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demandeur: ${widget.request.nomComplet}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Email: ${widget.request.email}'),
          Text('Type: ${widget.request.typeCompteFormate}'),
          if (widget.request.compagnieAssurance.isNotEmpty)
            Text('Compagnie: ${widget.request.compagnieAssurance}'),
          if (widget.request.agence.isNotEmpty)
            Text('Agence: ${widget.request.agence}'),
        ],
      ),
    );
  }

  /// ⚙️ Options d'approbation
  Widget _buildApprovalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options d\'approbation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ModernTheme.spacingS),
        CheckboxListTile(
          title: const Text('Créer automatiquement le compte'),
          subtitle: const Text('Le compte sera créé avec les informations fournies'),
          value: _createAccount,
          onChanged: (value) => setState(() => _createAccount = value ?? true),
          activeColor: ModernTheme.successColor,
        ),
        CheckboxListTile(
          title: const Text('Envoyer une notification'),
          subtitle: const Text('Notifier le demandeur par email'),
          value: _sendNotification,
          onChanged: (value) => setState(() => _sendNotification = value ?? true),
          activeColor: ModernTheme.successColor,
        ),
      ],
    );
  }

  /// 💬 Champ de commentaire
  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commentaire (optionnel)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ModernTheme.spacingS),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ajouter un commentaire pour le demandeur...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
            ),
            contentPadding: const EdgeInsets.all(ModernTheme.spacingM),
          ),
        ),
      ],
    );
  }

  /// ✅ Gérer l'approbation
  Future<void> _handleApproval() async {
    final success = await ref.read(requestActionsProvider.notifier).approveRequest(
      widget.request.id,
      widget.adminId,
      commentaire: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande de ${widget.request.nomComplet} approuvée avec succès'),
          backgroundColor: ModernTheme.successColor,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Naviguer vers les détails du compte créé
            },
          ),
        ),
      );
    }
  }
}

/// ❌ Dialogue de confirmation de rejet
class RejectionDialog extends ConsumerStatefulWidget {
  final ProfessionalRequestModel request;
  final String adminId;

  const RejectionDialog({
    super.key,
    required this.request,
    required this.adminId,
  });

  @override
  ConsumerState<RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends ConsumerState<RejectionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  bool _sendNotification = true;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionsState = ref.watch(requestActionsProvider);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.cancel,
              color: ModernTheme.errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: ModernTheme.spacingM),
          const Expanded(
            child: Text(
              'Rejeter la demande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du demandeur
            _buildRequestInfo(),
            
            const SizedBox(height: ModernTheme.spacingL),
            
            // Raison du rejet
            _buildRejectionReason(),
            
            const SizedBox(height: ModernTheme.spacingM),
            
            // Options de notification
            _buildNotificationOption(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: actionsState.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: actionsState.isLoading || _reasonController.text.trim().isEmpty
              ? null
              : _handleRejection,
          icon: actionsState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.close),
          label: const Text('Rejeter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ModernTheme.errorColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 📋 Informations de la demande
  Widget _buildRequestInfo() {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: BoxDecoration(
        color: ModernTheme.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: ModernTheme.errorColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demandeur: ${widget.request.nomComplet}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Email: ${widget.request.email}'),
          Text('Type: ${widget.request.typeCompteFormate}'),
        ],
      ),
    );
  }

  /// 📝 Raison du rejet
  Widget _buildRejectionReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Raison du rejet *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ModernTheme.spacingS),
        
        // Raisons prédéfinies
        ...rejectionReasons.map((reason) => RadioListTile<String>(
          title: Text(reason),
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
              if (value != null) {
                _reasonController.text = value;
              }
            });
          },
          activeColor: ModernTheme.errorColor,
        )),
        
        const SizedBox(height: ModernTheme.spacingS),
        
        // Raison personnalisée
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Raison détaillée',
            hintText: 'Expliquez la raison du rejet...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
            ),
            contentPadding: const EdgeInsets.all(ModernTheme.spacingM),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() => _selectedReason = null);
            }
          },
        ),
      ],
    );
  }

  /// 🔔 Option de notification
  Widget _buildNotificationOption() {
    return CheckboxListTile(
      title: const Text('Notifier le demandeur'),
      subtitle: const Text('Envoyer un email avec la raison du rejet'),
      value: _sendNotification,
      onChanged: (value) => setState(() => _sendNotification = value ?? true),
      activeColor: ModernTheme.errorColor,
    );
  }

  /// ❌ Gérer le rejet
  Future<void> _handleRejection() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    final success = await ref.read(requestActionsProvider.notifier).rejectRequest(
      widget.request.id,
      widget.adminId,
      commentaire: reason,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande de ${widget.request.nomComplet} rejetée'),
          backgroundColor: ModernTheme.errorColor,
        ),
      );
    }
  }

  /// 📝 Raisons de rejet prédéfinies
  static const List<String> rejectionReasons = [
    'Documents incomplets ou illisibles',
    'Informations incorrectes ou incohérentes',
    'Qualifications insuffisantes',
    'Compagnie d\'assurance non reconnue',
    'Doublon de demande existante',
  ];
}
