import 'package:flutter/material.dart';
import 'services/firebase_service.dart';

class AmendeFormScreen extends StatefulWidget {
  const AmendeFormScreen({super.key});

  @override
  State<AmendeFormScreen> createState() => _AmendeFormScreenState();
}

class _AmendeFormScreenState extends State<AmendeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _typeController = TextEditingController();
  final _montantController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cleController = TextEditingController();

  DateTime? _dateLimite;
  bool _isLoading = false;

  @override
  void dispose() {
    _typeController.dispose();
    _montantController.dispose();
    _numeroController.dispose();
    _cleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 45)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateLimite = picked;
      });
    }
  }

  Future<void> _saveAmende() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateLimite == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez selectionner une date limite'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final montant = double.tryParse(_montantController.text) ?? 0;
      final montantCentimes = (montant * 100).toInt();

      FirebaseService.instance.createAmende(
        type: _typeController.text.trim(),
        montantCentimes: montantCentimes,
        dateLimite: _dateLimite!,
        numeroTelepaiement: _numeroController.text.trim().isEmpty
            ? null
            : _numeroController.text.trim(),
        cle: _cleController.text.trim().isEmpty
            ? null
            : _cleController.text.trim(),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une amende'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Enregistrement en cours...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Radar', child: Text('Radar')),
                        DropdownMenuItem(
                            value: 'Stationnement',
                            child: Text('Stationnement')),
                        DropdownMenuItem(
                            value: 'Feu rouge', child: Text('Feu rouge')),
                        DropdownMenuItem(
                            value: 'Téléphone', child: Text('Téléphone')),
                        DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                      ],
                      onChanged: (value) {
                        _typeController.text = value ?? '';
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _montantController,
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date limite',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dateLimite == null
                              ? 'Sélectionner'
                              : '${_dateLimite!.day}/${_dateLimite!.month}/${_dateLimite!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _numeroController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cleController,
                      decoration: const InputDecoration(
                        labelText: 'Clé (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveAmende,
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
