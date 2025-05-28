import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/email_validator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../constat/providers/session_provider.dart';
import 'conducteur_declaration_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({Key? key}) : super(key: key);

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  int _nombreConducteurs = 2;
  final List<TextEditingController> _emailControllers = [];
  final List<String> _positions = ['A', 'B', 'C', 'D', 'E', 'F'];
  final List<Color> _positionColors = [
    const Color(0xFF10B981), // A - Vert
    const Color(0xFFEF4444), // B - Rouge
    const Color(0xFF6366F1), // C - Bleu
    const Color(0xFFF59E0B), // D - Orange
    const Color(0xFF8B5CF6), // E - Violet
    const Color(0xFF06B6D4), // F - Cyan
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _emailControllers.clear();
    for (int i = 0; i < 6; i++) {
      _emailControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _creerSession() async {
    try {
      // Validation des emails
      List<String> emails = [];
      for (int i = 1; i < _nombreConducteurs; i++) {
        final email = _emailControllers[i].text.trim();
        if (email.isNotEmpty) {
          if (!EmailValidator.isValid(email)) {
            throw Exception('Email invalide: $email');
          }
          emails.add(email);
        }
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer la session
      final sessionId = await sessionProvider.creerSession(
        nombreConducteurs: _nombreConducteurs,
        emailsInvites: emails,
        createdBy: authProvider.currentUser!.id,
      );

      if (mounted) {
        // Naviguer vers l'écran de déclaration avec la session
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConducteurDeclarationScreen(
              sessionId: sessionId,
              conducteurPosition: 'A', // Le créateur est toujours A
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Nouveau Constat',
        backgroundColor: Color(0xFF6366F1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 24),
            _buildNombreConducteursSelector(),
            const SizedBox(height: 24),
            _buildConducteursInfo(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Constat Collaboratif',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Invitez les autres conducteurs à remplir le constat ensemble',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNombreConducteursSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nombre de conducteurs impliqués',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              final nombre = index + 2;
              final isSelected = _nombreConducteurs == nombre;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _nombreConducteurs = nombre;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$nombre',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'conducteurs',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConducteursInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conducteurs impliqués',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_nombreConducteurs, (index) {
            final position = _positions[index];
            final color = _positionColors[index];
            final isCurrentUser = index == 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            position,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCurrentUser ? 'Vous (Conducteur $position)' : 'Conducteur $position',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            Text(
                              isCurrentUser ? 'Créateur du constat' : 'Sera invité par email',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VOUS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!isCurrentUser) ...[
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _emailControllers[index],
                      label: 'Email du conducteur $position',
                      hintText: 'exemple@email.com',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isNotEmpty == true && !EmailValidator.isValid(value!)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les autres conducteurs recevront un email avec un lien pour rejoindre ce constat.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Créer le Constat Collaboratif',
            onPressed: _creerSession,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Remplir Seul (Mode Simple)',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConducteurDeclarationScreen(
                    sessionId: null,
                    conducteurPosition: 'A',
                  ),
                ),
              );
            },
            color: const Color(0xFF6B7280),
            isOutlined: true,
          ),
        ),
      ],
    );
  }
}
