import 'package:flutter/material.dart';
import '../models/amende.dart';

class AmendeDetailScreen extends StatelessWidget {
  final Amende amende;

  const AmendeDetailScreen({super.key, required this.amende});

  @override
  Widget build(BuildContext context) {
    final euros = (amende.montantCentimes / 100).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’amende')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type : ${amende.type}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Montant : $euros €'),
            Text('Statut : ${amende.statut}'),
            Text('Échéance : ${amende.dateLimite.toLocal().toString().split(" ").first}'),
            if (amende.numeroTelepaiement != null)
              Text('Télépaiement : ${amende.numeroTelepaiement}'),
            if (amende.cle != null)
              Text('Clé : ${amende.cle}'),
            if (amende.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Image.network(amende.imageUrl!),
              ),
          ],
        ),
      ),
    );
  }
}
