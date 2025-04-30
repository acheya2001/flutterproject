// lib/presentation/widgets/report/insurance_info_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:constat_tunisie/data/models/insurance_model.dart';
import 'package:constat_tunisie/data/services/insurance_service.dart';

class InsuranceInfoForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onSaved;
  final Map<String, dynamic> initialData;

  const InsuranceInfoForm({
    Key? key,
    required this.formKey,
    required this.onSaved,
    required this.initialData,
  }) : super(key: key);

  @override
  State<InsuranceInfoForm> createState() => _InsuranceInfoFormState();
}

class _InsuranceInfoFormState extends State<InsuranceInfoForm> {
  final InsuranceService _insuranceService = InsuranceService();
  final TextEditingController _contractNumberController = TextEditingController();
  final TextEditingController _validFromController = TextEditingController();
  final TextEditingController _validToController = TextEditingController();
  
  List<InsuranceCompany> _companies = [];
  List<InsuranceAgency> _agencies = [];
  
  String? _selectedCompanyId;
  String? _selectedAgencyId;
  DateTime? _validFromDate;
  DateTime? _validToDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsuranceCompanies();
    
    // Initialiser les contrôleurs avec les données existantes
    _contractNumberController.text = widget.initialData['insuranceContractNumber'] ?? '';
    _validFromController.text = widget.initialData['insuranceValidFrom'] != null 
        ? DateFormat('dd/MM/yyyy').format(widget.initialData['insuranceValidFrom'])
        : '';
    _validToController.text = widget.initialData['insuranceValidTo'] != null 
        ? DateFormat('dd/MM/yyyy').format(widget.initialData['insuranceValidTo'])
        : '';
    _selectedCompanyId = widget.initialData['insuranceCompanyId'];
    _selectedAgencyId = widget.initialData['insuranceAgencyId'];
    _validFromDate = widget.initialData['insuranceValidFrom'];
    _validToDate = widget.initialData['insuranceValidTo'];
    
    if (_selectedCompanyId != null) {
      _loadAgencies(_selectedCompanyId!);
    }
  }

  @override
  void dispose() {
    _contractNumberController.dispose();
    _validFromController.dispose();
    _validToController.dispose();
    super.dispose();
  }

  Future<void> _loadInsuranceCompanies() async {
    try {
      final companies = await _insuranceService.getAllInsuranceCompanies();
      if (mounted) {
        setState(() {
          _companies = companies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des compagnies d\'assurance: $e')),
        );
      }
    }
  }

  Future<void> _loadAgencies(String companyId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final agencies = await _insuranceService.getAgenciesByInsurance(companyId);
      
      if (mounted) {
        setState(() {
          _agencies = agencies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des agences: $e')),
        );
      }
    }
  }

  Future<void> _selectValidFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validFromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (picked != null && picked != _validFromDate) {
      if (mounted) {
        setState(() {
          _validFromDate = picked;
          _validFromController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    }
  }

  Future<void> _selectValidToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validToDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (picked != null && picked != _validToDate) {
      if (mounted) {
        setState(() {
          _validToDate = picked;
          _validToController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: widget.formKey,
            onChanged: () {
              widget.formKey.currentState?.validate();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  decoration: const InputDecoration(
                    labelText: 'Compagnie d\'assurance *',
                  ),
                  items: _companies.map((company) {
                    return DropdownMenuItem<String>(
                      value: company.id,
                      child: Text(company.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCompanyId = value;
                      _selectedAgencyId = null;
                      _agencies = [];
                    });
                    if (value != null) {
                      _loadAgencies(value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une compagnie d\'assurance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedAgencyId,
                  decoration: const InputDecoration(
                    labelText: 'Agence d\'assurance *',
                  ),
                  items: _agencies.map((agency) {
                    return DropdownMenuItem<String>(
                      value: agency.id,
                      child: Text(agency.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAgencyId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une agence d\'assurance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _contractNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de contrat *',
                    hintText: 'Ex: POL123456789',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le numéro de contrat';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _validFromController,
                  decoration: const InputDecoration(
                    labelText: 'Valide du *',
                    hintText: 'JJ/MM/AAAA',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _selectValidFromDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la date de début de validité';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _validToController,
                  decoration: const InputDecoration(
                    labelText: 'Valide au *',
                    hintText: 'JJ/MM/AAAA',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _selectValidToDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la date de fin de validité';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
  }

  // Cette méthode est appelée lorsque le formulaire est soumis
  void save() {
    final data = {
      'insuranceCompanyId': _selectedCompanyId,
      'insuranceAgencyId': _selectedAgencyId,
      'insuranceContractNumber': _contractNumberController.text,
      'insuranceValidFrom': _validFromDate,
      'insuranceValidTo': _validToDate,
    };
    widget.onSaved(data);
  }
}