import 'package:flutter/material.dart';

class AmendeFormScreen extends StatefulWidget {
  const AmendeFormScreen({super.key});

  @override
  State<AmendeFormScreen> createState() => _AmendeFormScreenState();
}

class _AmendeFormScreenState extends State<AmendeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String type = '';
  int montantCentimes = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une amende')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Type'),
                onSaved: (val) => type = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Montant (€)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => montantCentimes = ((double.tryParse(val ?? '0') ?? 0) * 100).toInt(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _formKey.currentState?.save();
                  Navigator.of(context).pop(true); // retourne true à Dashboard
                },
                child: const Text('Valider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
