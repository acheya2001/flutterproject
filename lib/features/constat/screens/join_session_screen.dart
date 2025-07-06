import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/email_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/session_constat_model.dart';
import '../providers/session_provider.dart';
import '../../conducteur/screens/conducteur_declaration_screen.dart';

class JoinSessionScreen extends ConsumerStatefulWidget {
  final String? sessionCodeFromDeepLink;

  const JoinSessionScreen({Key? key, this.sessionCodeFromDeepLink}) : super(key: key);

  @override
  ConsumerState<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen> {
  final _sessionCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionCodeFromDeepLink != null) {
      _sessionCodeController.text = widget.sessionCodeFromDeepLink!;
    }
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinSession(BuildContext context) async {
    if (_sessionCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un code de session')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final authProviderInstance = ref.read(authProvider);
      final sessionProvider = SessionProvider(
        sessionService: SessionService(),
      );

      if (authProviderInstance.currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final sessionCode = _sessionCodeController.text.trim();
      final SessionConstatModel? session = await sessionProvider.rejoindreSession(
        sessionCode,
        authProviderInstance.currentUser!.id,
      );

      if (session == null) {
        throw Exception('Session non trouvée ou impossible de rejoindre.');
      }

      String? conducteurPosition;
      // Null check for session before accessing conducteursInfo
      if (session.conducteursInfo.isNotEmpty) {
        for (var entry in session.conducteursInfo.entries) {
          if (entry.value.userId == authProviderInstance.currentUser!.id || entry.value.email == authProviderInstance.currentUser!.email) {
            conducteurPosition = entry.key;
            break;
          }
        }
      }

      if (conducteurPosition == null) {
        throw Exception('Vous n\'êtes pas autorisé à rejoindre cette session.');
      }

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConducteurDeclarationScreen(
            sessionId: session.id,
            conducteurPosition: conducteurPosition!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Rejoindre une Session'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(
              controller: _sessionCodeController,
              label: 'Code de Session',
              hintText: 'Entrez le code de la session',
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: 'Rejoindre',
                    onPressed: () => _joinSession(context),
                  ),
          ],
        ),
      ),
    );
  }
}