// lib/screens/amende_form_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AmendeFormScreen extends StatefulWidget {
  const AmendeFormScreen({super.key});

  @override
  State<AmendeFormScreen> createState() => _AmendeFormScreenState();
}

class _AmendeFormScreenState extends State<AmendeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService();

  String _type = 'Radar';
  final _montantCtrl = TextEditingController();
  DateTime? _dateLimite;
  final _numCtrl = TextEditingController();
  final _cleCtrl = TextEditingController();

  @override
  void dispose() {
    _montantCtrl.dispose();
    _numCtrl.dispose();
    _cleCtrl.dispose();
    super.dispose();
  }

  int _eurosToCentimes(String txt) {
    final cleaned = txt.replaceAll(',', '.').trim();
    final euros = double.tryParse(cleaned);
    if (euros == null) throw 'Montant invalide';
    return (euros * 100).round();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDate: _dateLimite ?? now.add(const Duration(days: 15)),
      helpText: 'Sélectionne la date limite de paiement',
    );
    if (d != null) setState(() => _dateLimite = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final id = await _service.createAmende(
        type: _type,
        montantCentimes: _eurosToCentimes(_montantCtrl.text),
        dateLimite: _dateLimite!,
        numeroTelepaiement: _numCtrl.text.isEmpty ? null : _numCtrl.text.trim(),
        cle: _cleCtrl.text.isEmpty ? null : _cleCtrl.text.trim(),
      );
      // Option: programmer notifications ici si tu utilises déjà NotificationService
      // await NotificationService.scheduleForAmende(...);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateLimite == null
        ? 'Choisir'
        : _dateLimite!.toLocal().toString().split(' ').first;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle amende')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'Radar', child: Text('Radar')),
                DropdownMenuItem(value: 'Stationnement', child: Text('Stationnement')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'Radar'),
            ),
            TextFormField(
              controller: _montantCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant (€)',
                hintText: 'ex: 90 ou 90,50',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Montant requis';
                final cleaned = v.replaceAll(',', '.');
                if (double.tryParse(cleaned) == null) return 'Format invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Échéance: $dateLabel')),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Sélectionner'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numCtrl,
              decoration: const InputDecoration(
                labelText: 'N° de télépaiement (optionnel)',
              ),
            ),
            TextFormField(
              controller: _cleCtrl,
              decoration: const InputDecoration(
                labelText: 'Clé (optionnel)',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: (_dateLimite != null) ? _submit : null,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            )
          ],
        ),
      ),
    );
  }
}
