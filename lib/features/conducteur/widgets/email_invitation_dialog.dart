import 'package:flutter/material.dart';
import '../../../core/services/email_validation_service.dart';

import '../../../core/services/test_emailjs_service.dart';
import '../../../core/services/webhook_email_service.dart';
import '../../../core/services/firebase_email_test_service.dart';
import '../../../core/services/firebase_email_service.dart'; // 🔥 NOUVEAU IMPORT GMAIL API
import '../../../core/services/test_email_service.dart';
import '../../../core/services/gmail_oauth2_test_service.dart';
import '../../../core/utils/session_utils.dart';

class EmailInvitationDialog extends StatefulWidget {
  final int nombreConducteurs;
  final Color currentPositionColor;

  const EmailInvitationDialog({
    Key? key,
    required this.nombreConducteurs,
    required this.currentPositionColor,
  }) : super(key: key);

  @override
  State<EmailInvitationDialog> createState() => _EmailInvitationDialogState();
}

class _EmailInvitationDialogState extends State<EmailInvitationDialog> {
  late List<TextEditingController> _controllers;
  late List<EmailValidationResult?> _validationResults;
  bool _isValidating = false;
  bool _canInvite = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.nombreConducteurs - 1, 
      (_) => TextEditingController(),
    );
    _validationResults = List.generate(
      widget.nombreConducteurs - 1, 
      (_) => null,
    );
    
    // Ajouter des listeners pour validation en temps réel
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() => _validateEmail(i));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _validateEmail(int index) async {
    final email = _controllers[index].text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _validationResults[index] = null;
        _updateCanInvite();
      });
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      final result = await EmailValidationService.validateEmail(email);
      if (mounted) {
        setState(() {
          _validationResults[index] = result;
          _isValidating = false;
          _updateCanInvite();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationResults[index] = EmailValidationResult(
            isValid: false,
            exists: false,
            error: 'Erreur de validation',
          );
          _isValidating = false;
          _updateCanInvite();
        });
      }
    }
  }

  void _updateCanInvite() {
    final nonEmptyEmails = _controllers
        .asMap()
        .entries
        .where((entry) => entry.value.text.trim().isNotEmpty)
        .toList();

    if (nonEmptyEmails.isEmpty) {
      _canInvite = false;
      return;
    }

    _canInvite = nonEmptyEmails.every((entry) {
      final result = _validationResults[entry.key];
      return result != null && result.isValidAndExists;
    });
  }

  List<String> _getValidEmails() {
    List<String> validEmails = [];
    for (int i = 0; i < _controllers.length; i++) {
      final email = _controllers[i].text.trim();
      final result = _validationResults[i];
      
      if (email.isNotEmpty && result != null && result.isValidAndExists) {
        validEmails.add(email);
      }
    }
    return validEmails;
  }

  Widget _buildEmailField(int index) {
    final position = ['B', 'C', 'D', 'E', 'F'][index];
    final color = SessionUtils.getPositionColor(position);
    final result = _validationResults[index];
    final email = _controllers[index].text.trim();

    Color? borderColor;
    Widget? suffixIcon;
    String? helperText;

    if (email.isNotEmpty && result != null) {
      if (result.isValidAndExists) {
        borderColor = Colors.green;
        suffixIcon = const Icon(Icons.check_circle, color: Colors.green);
        helperText = 'Email valide ✓';
      } else {
        borderColor = Colors.red;
        suffixIcon = const Icon(Icons.error, color: Colors.red);
        helperText = result.error ?? 'Email invalide ou inexistant';
      }
    } else if (email.isNotEmpty && _isValidating) {
      suffixIcon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      helperText = 'Vérification en cours...';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controllers[index],
            decoration: InputDecoration(
              labelText: 'Email conducteur $position',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  position,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: borderColor ?? Colors.grey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: borderColor ?? Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: borderColor ?? widget.currentPositionColor,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                helperText,
                style: TextStyle(
                  fontSize: 12,
                  color: borderColor ?? Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Inviter les autres conducteurs',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entrez les adresses email des autres conducteurs impliqués dans l\'accident:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                widget.nombreConducteurs - 1,
                (index) => _buildEmailField(index),
              ),
              if (_isValidating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Validation des emails...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              const Text(
                '💡 Conseils:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Text(
                '• Vérifiez que les emails sont corrects\n'
                '• Les conducteurs recevront un lien d\'invitation\n'
                '• Ils pourront rejoindre la session avec le code',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              // Boutons de test d'email
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            debugPrint('[EmailInvitationDialog] Test Firebase Functions...');
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final success = await FirebaseEmailTestService.testEmailSending(
                              testEmail: 'hammami123rahma@gmail.com',
                            );
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(success
                                    ? '✅ Test Firebase réussi! Vérifiez votre email.'
                                    : '❌ Test Firebase échoué. Vérifiez les logs.'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud, size: 14),
                          label: const Text(
                            'Test Firebase',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            debugPrint('[EmailInvitationDialog] Test Gmail API...');
                            final scaffoldMessenger = ScaffoldMessenger.of(context);

                            try {
                              final success = await FirebaseEmailService.envoyerInvitation(
                                email: 'hammami123rahma@gmail.com',
                                sessionCode: 'TEST${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                sessionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
                                customMessage: '🔥 Test Gmail API depuis le bouton Test Email ! Si vous recevez cet email, Gmail API fonctionne parfaitement !',
                              );

                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                      ? '🔥 ✅ Gmail API fonctionne ! Vérifiez votre email.'
                                      : '❌ Gmail API échoué. Vérifiez les logs.'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Erreur Gmail API: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.email, size: 16),
                          label: const Text(
                            '🔥 Gmail API',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: Colors.green, width: 2),
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 🔥 NOUVEAU BOUTON GMAIL API
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        debugPrint('[EmailInvitationDialog] 🔥 Test Gmail API...');
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        try {
                          final success = await FirebaseEmailService.envoyerInvitation(
                            email: 'hammami123rahma@gmail.com',
                            sessionCode: 'GMAIL${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            sessionId: 'gmail_test_${DateTime.now().millisecondsSinceEpoch}',
                            customMessage: '🔥 Test Gmail API depuis votre application Flutter ! Si vous recevez cet email, Gmail API fonctionne parfaitement !',
                          );

                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(success
                                  ? '🔥 ✅ Gmail API fonctionne ! Vérifiez votre email.'
                                  : '❌ Gmail API échoué. Vérifiez les logs.'),
                                backgroundColor: success ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('[EmailInvitationDialog] ❌ Erreur Gmail API: $e');
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('❌ Erreur Gmail API: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.mark_email_read, size: 16, color: Colors.white),
                      label: const Text(
                        '🔥 Test Gmail API (NOUVEAU)',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        debugPrint('[EmailInvitationDialog] Test de simulation...');
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final results = await TestEmailService.testCompletSimulation();
                        if (mounted) {
                          final success = results['overall_success'] as bool;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(success
                                ? '🧪 Simulation réussie! Vérifiez les logs pour voir le contenu.'
                                : '❌ Simulation échouée. Vérifiez les logs.'),
                              backgroundColor: success ? Colors.purple : Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.science, size: 14),
                      label: const Text(
                        '🧪 Test Simulation (Logs)',
                        style: TextStyle(fontSize: 10),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        side: const BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Bouton test Gmail OAuth2 (NOUVELLE SOLUTION RECOMMANDÉE)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    debugPrint('[EmailInvitationDialog] Test Gmail OAuth2...');
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final success = await GmailOAuth2TestService.testGmailOAuth2(
                      email: 'hammami123rahma@gmail.com',
                      sessionCode: 'GMAIL${DateTime.now().millisecondsSinceEpoch % 1000}',
                      conducteurNom: 'Test Gmail OAuth2',
                    );

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(success
                            ? '✅ Test Gmail OAuth2 réussi! Vérifiez votre email.'
                            : '❌ Test Gmail OAuth2 échoué. Configurez d\'abord OAuth2.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.mail, size: 16),
                  label: const Text(
                    '📧 TEST GMAIL OAUTH2 (RECOMMANDÉ)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: const BorderSide(color: Colors.green, width: 2),
                    foregroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Bouton test Webhook (VRAIMENT universel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    debugPrint('[EmailInvitationDialog] Test Webhook Universel...');
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final success = await WebhookEmailService.envoyerInvitation(
                      email: 'motex15133@ihnpo.com', // Email temp-mail
                      sessionCode: 'TEST456',
                      sessionId: 'test_webhook_id',
                      customMessage: 'Test Webhook - Fonctionne avec TOUS les emails sans restriction !',
                    );

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(success
                            ? '✅ Test Webhook réussi! Vérifiez temp-mail dans 1 minute.'
                            : '❌ Test Webhook échoué. Vérifiez les logs Flutter.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.webhook, size: 16),
                  label: const Text(
                    '🌐 TEST WEBHOOK UNIVERSEL',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: const BorderSide(color: Colors.teal, width: 2),
                    foregroundColor: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Bouton test EmailJS
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    debugPrint('[EmailInvitationDialog] Test EmailJS Direct...');
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final success = await TestEmailJSService.testEmailJS(
                      email: 'motex15133@ihnpo.com', // Email temp-mail
                    );

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(success
                            ? '✅ Test EmailJS réussi! Vérifiez temp-mail dans 30 secondes.'
                            : '❌ Test EmailJS échoué. Vérifiez les logs Flutter.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.rocket_launch, size: 16),
                  label: const Text(
                    '🧪 TEST EMAILJS DIRECT',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: const BorderSide(color: Colors.purple, width: 2),
                    foregroundColor: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            debugPrint('[EmailInvitationDialog] Dialog annulé');
            Navigator.of(context).pop(<String>[]);
          },
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _canInvite && !_isValidating
              ? () {
                  final validEmails = _getValidEmails();
                  debugPrint('[EmailInvitationDialog] Emails validés: $validEmails');
                  Navigator.of(context).pop(validEmails);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.currentPositionColor,
            foregroundColor: Colors.white,
          ),
          child: _isValidating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Inviter'),
        ),
      ],
    );
  }
}
