import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../models/participant_model.dart';
import '../declaration_wizard_screen.dart';

/// 👥 Étape 3: Gestion des participants (invitations)
class Step3Participants extends StatefulWidget {
  final WizardData wizardData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step3Participants({
    super.key,
    required this.wizardData,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step3Participants> createState() => _Step3ParticipantsState();
}

class _Step3ParticipantsState extends State<Step3Participants> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          const Text(
            'Participants',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invitez les autres conducteurs et témoins à remplir leur partie',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Contenu principal
          Expanded(
            child: widget.wizardData.participants.isEmpty
                ? _buildEmptyState()
                : _buildParticipantsList(),
          ),

          // Boutons d'action
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun participant invité',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous pouvez inviter d\'autres conducteurs ou témoins',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Options d'invitation
          Column(
            children: [
              CustomButton(
                text: 'Inviter par email/téléphone',
                onPressed: () => _showInviteDialog(),
                icon: Icons.email,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Générer QR Code',
                onPressed: () => _showQRCodeDialog(),
                backgroundColor: Colors.green,
                icon: Icons.qr_code,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onNext,
                child: const Text('Passer cette étape'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Column(
      children: [
        // En-tête avec boutons d'ajout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.wizardData.participants.length} participant(s) invité(s)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _showInviteDialog(),
                  icon: const Icon(Icons.email),
                  tooltip: 'Inviter par email',
                ),
                IconButton(
                  onPressed: () => _showQRCodeDialog(),
                  icon: const Icon(Icons.qr_code),
                  tooltip: 'QR Code',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Liste des participants
        Expanded(
          child: ListView.builder(
            itemCount: widget.wizardData.participants.length,
            itemBuilder: (context, index) {
              final participant = widget.wizardData.participants[index];
              return _buildParticipantCard(participant, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant, int index) {
    final role = participant['role'] as RoleInAccident;
    final emailOrPhone = participant['emailOrPhone'] as String;
    final isOwner = participant['isOwner'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getRoleIcon(role),
                        color: _getRoleColor(role),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emailOrPhone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          role.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditParticipantDialog(participant, index);
                    } else if (value == 'delete') {
                      _removeParticipant(index);
                    }
                  },
                ),
              ],
            ),
            
            if (isOwner) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Text(
                  'Propriétaire du véhicule',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'En attente d\'acceptation',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Précédent',
            onPressed: widget.onPrevious,
            backgroundColor: Colors.grey[300],
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Suivant',
            onPressed: widget.onNext,
            icon: Icons.arrow_forward,
          ),
        ),
      ],
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteDialog(
        onInvite: (emailOrPhone, role, isOwner) {
          if (mounted) setState(() {
            widget.wizardData.participants.add({
              'emailOrPhone': emailOrPhone,
              'role': role,
              'isOwner': isOwner,
              'vehicleRef': null, // TODO: Associer à un véhicule
            });
          });
        },
      ),
    );
  }

  void _showEditParticipantDialog(Map<String, dynamic> participant, int index) {
    showDialog(
      context: context,
      builder: (context) => _InviteDialog(
        participant: participant,
        onInvite: (emailOrPhone, role, isOwner) {
          setState(() {
            widget.wizardData.participants[index] = {
              'emailOrPhone': emailOrPhone,
              'role': role,
              'isOwner': isOwner,
              'vehicleRef': participant['vehicleRef'],
            };
          });
        },
      ),
    );
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code d\'invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: 'https://app/constat/invite?token=DEMO_TOKEN',
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scannez ce QR code pour rejoindre le constat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _removeParticipant(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le participant'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette invitation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (mounted) setState(() {
                widget.wizardData.participants.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(RoleInAccident role) {
    switch (role) {
      case RoleInAccident.conducteur:
        return Colors.blue;
      case RoleInAccident.autreConducteur:
        return Colors.orange;
      case RoleInAccident.temoin:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(RoleInAccident role) {
    switch (role) {
      case RoleInAccident.conducteur:
        return Icons.person;
      case RoleInAccident.autreConducteur:
        return Icons.person_outline;
      case RoleInAccident.temoin:
        return Icons.visibility;
    }
  }
}

/// 📧 Dialog pour inviter un participant
class _InviteDialog extends StatefulWidget {
  final Map<String, dynamic>? participant;
  final Function(String, RoleInAccident, bool) onInvite;

  const _InviteDialog({
    this.participant,
    required this.onInvite,
  });

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  RoleInAccident _selectedRole = RoleInAccident.autreConducteur;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    if (widget.participant != null) {
      _emailPhoneController.text = widget.participant!['emailOrPhone'];
      _selectedRole = widget.participant!['role'];
      _isOwner = widget.participant!['isOwner'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.participant == null ? 'Inviter un participant' : 'Modifier l\'invitation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailPhoneController,
              decoration: const InputDecoration(
                labelText: 'Email ou téléphone *',
                hintText: 'exemple@email.com ou +216 12 345 678',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un email ou téléphone';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<RoleInAccident>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rôle dans l\'accident',
              ),
              items: RoleInAccident.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (mounted) setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            
            if (_selectedRole == RoleInAccident.autreConducteur) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Propriétaire du véhicule'),
                subtitle: const Text('Cette personne est-elle propriétaire de son véhicule ?'),
                value: _isOwner,
                onChanged: (value) {
                  if (mounted) setState(() {
                    _isOwner = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveInvitation,
          child: const Text('Inviter'),
        ),
      ],
    );
  }

  void _saveInvitation() {
    if (_formKey.currentState!.validate()) {
      widget.onInvite(
        _emailPhoneController.text,
        _selectedRole,
        _selectedRole == RoleInAccident.autreConducteur ? _isOwner : false,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    super.dispose();
  }
}

