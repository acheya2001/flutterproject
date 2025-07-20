import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/insurance_company.dart';
import 'company_form_screen.dart';

/// 📋 Écran de détails d'une compagnie
class CompanyDetailsScreen extends StatelessWidget {
  final InsuranceCompany company;

  const CompanyDetailsScreen({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final companyColor = _getCompanyColor(company.nom);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          company.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: companyColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [companyColor, companyColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _editCompany(context),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Modifier',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(),
            
            const SizedBox(height: 16),
            
            // Informations générales
            _buildInfoCard(
              title: 'Informations générales',
              icon: Icons.business,
              children: [
                _buildInfoRow('Nom', company.nom),
                if (company.code != null) _buildInfoRow('Code', company.code!),
                _buildInfoRow('Type', company.type),
                _buildInfoRow('Statut', company.status == 'active' ? 'Active' : 'Inactive'),
                _buildInfoRow('Date de création', _formatDate(company.createdAt)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Coordonnées
            _buildInfoCard(
              title: 'Coordonnées',
              icon: Icons.contact_mail,
              children: [
                _buildContactRow('Email', company.email, Icons.email, () => _launchEmail(company.email)),
                _buildContactRow('Téléphone', company.telephone, Icons.phone, () => _launchPhone(company.telephone)),
                _buildInfoRow('Adresse', company.adresse),
                if (company.siteWeb != null)
                  _buildContactRow('Site web', company.siteWeb!, Icons.language, () => _launchUrl(company.siteWeb!)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Admin assigné
            if (company.adminCompagnieNom != null)
              _buildInfoCard(
                title: 'Administrateur assigné',
                icon: Icons.person,
                children: [
                  _buildInfoRow('Nom', company.adminCompagnieNom!),
                  if (company.adminCompagnieEmail != null)
                    _buildContactRow('Email', company.adminCompagnieEmail!, Icons.email, () => _launchEmail(company.adminCompagnieEmail!)),
                ],
              )
            else
              _buildInfoCard(
                title: 'Administrateur assigné',
                icon: Icons.person_off,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade600),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Aucun administrateur assigné à cette compagnie',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _assignAdmin(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assigner un administrateur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final isActive = company.status == 'active';
    final companyColor = _getCompanyColor(company.nom);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [companyColor, companyColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: companyColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo avec animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 16),

            // Nom de la compagnie
            Text(
              company.nom,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Code de la compagnie
            if (company.code != null)
              Text(
                'Code: ${company.code}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

            const SizedBox(height: 16),

            // Badges de statut et type
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        company.type == 'Takaful'
                            ? Icons.mosque_rounded
                            : Icons.account_balance_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        company.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444)).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final companyColor = _getCompanyColor(company.nom);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: companyColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: companyColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [companyColor.withOpacity(0.1), companyColor.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: companyColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: companyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final companyColor = _getCompanyColor(company.nom);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: companyColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: companyColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: companyColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value, IconData icon, VoidCallback onTap) {
    final companyColor = _getCompanyColor(company.nom);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: companyColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: companyColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [companyColor, companyColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: companyColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: companyColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editCompany(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyFormScreen(company: company),
      ),
    );
  }

  void _assignAdmin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'assignation d\'admin - En cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 🎨 Obtenir une couleur unique pour chaque compagnie
  Color _getCompanyColor(String companyName) {
    final colors = [
      const Color(0xFF3B82F6), // Bleu
      const Color(0xFF10B981), // Vert
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Rouge
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Rose
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
    ];

    final hash = companyName.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
