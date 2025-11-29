// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../models/amende.dart';
import '../services/firebase_service.dart';
import '../amende_form_screen.dart';
import 'amende_detail_screen.dart';        // si ton détail est là               // on le crée au point 4
// Si le chemin de tes widgets diffère, ajuste les imports en conséquence.

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes amendes')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AmendeFormScreen()),
          );
          // Optionnel: Snackbar si created == true
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Amende ajoutée')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),

      body: StreamBuilder<List<Amende>>(
        stream: service.streamMyAmendes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Aucune amende pour l’instant.'));
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = data[i];
              final euros = (a.montantCentimes / 100).toStringAsFixed(2);

              return ListTile(
                title: Text('${a.type} · ${euros}€'),
                subtitle: Text(
                  'Statut: ${a.statut} · Échéance: ${a.dateLimite.toLocal().toString().split(" ").first}',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AmendeDetailScreen(amende: a),
                    ),
                  );
                },
                trailing: a.statut == 'en_attente'
                    ? TextButton(
                        onPressed: () => FirebaseService().markPayee(a.id),
                        child: const Text('Marquer payée'),
                      )
                    : const Icon(Icons.check, color: Colors.green),
              );
            },
          );
        },
      ),
    );
  }
}
