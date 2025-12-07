import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AmendeFormScreen extends StatefulWidget {
  const AmendeFormScreen({super.key});

  @override
  State<AmendeFormScreen> createState() => _AmendeFormScreenState();
}

class _AmendeFormScreenState extends State<AmendeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService.instance; // Utiliser instance
  
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

  /// Convertir euros en centimes
  int _eurosToCentimes(String txt) {
    final cleaned = txt.replaceAll(',', '.').trim();
    final euros = double.tryParse(cleaned);
    if (euros == null) throw 'Montant invalide';
    return (euros * 100).round();
  }

  /// Sélectionner une date
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

  /// Soumettre le formulaire
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _service.createAmende(
        type: _type,
        montantCentimes: _eurosToCentimes(_montantCtrl.text),
        dateLimite: _dateLimite!,
        numeroTelepaiement: _numCtrl.text.isEmpty ? null : _numCtrl.text.trim(),
        cle: _cleCtrl.text.isEmpty ? null : _cleCtrl.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateLimite == null
        ? 'Choisir'
        : '${_dateLimite!.day.toString().padLeft(2, '0')}/'
          '${_dateLimite!.month.toString().padLeft(2, '0')}/'
          '${_dateLimite!.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle amende'),
      ),
      
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type d'amende
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type d\'amende',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Radar', child: Text('Radar')),
                DropdownMenuItem(value: 'Stationnement', child: Text('Stationnement')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'Radar'),
            ),
            const SizedBox(height: 16),
            
            // Montant
            TextFormField(
              controller: _montantCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant (€)',
                hintText: 'ex: 90 ou 90,50',
                prefixIcon: Icon(Icons.euro),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Montant requis';
                final cleaned = v.replaceAll(',', '.');
                if (double.tryParse(cleaned) == null) return 'Format invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Date limite
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Date limite de paiement'),
                subtitle: Text(dateLabel),
                trailing: OutlinedButton(
                  onPressed: _pickDate,
                  child: const Text('Sélectionner'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Numéro de télépaiement (optionnel)
            TextFormField(
              controller: _numCtrl,
              decoration: const InputDecoration(
                labelText: 'N° de télépaiement (optionnel)',
                hintText: 'ex: 1234567890123456',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Clé (optionnel)
            TextFormField(
              controller: _cleCtrl,
              decoration: const InputDecoration(
                labelText: 'Clé (optionnel)',
                hintText: 'ex: 12',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            // Bouton d'enregistrement
            FilledButton.icon(
              onPressed: (_dateLimite != null) ? _submit : null,
              icon: const Icon(Icons.save),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: const Text(
                'Enregistrer',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}