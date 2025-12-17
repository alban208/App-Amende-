import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/amende.dart';
import '../amende_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Key unique pour forcer le rebuild du StreamBuilder
  Key _streamKey = UniqueKey();

  void _refreshStream() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService.instance;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes amendes'),
        actions: [
          // Bouton de rafraîchissement manuel
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _refreshStream,
          ),
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await service.signOut();
            },
          ),
        ],
      ),
      // Bouton flottant pour ajouter une amende
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AmendeFormScreen(),
            ),
          );

          if (created == true && mounted) {
            // Forcer le rafraîchissement du stream
            _refreshStream();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Amende ajoutée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          // En-tête avec info utilisateur
          if (user != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connecté en tant que:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'Utilisateur',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          // Liste des amendes
          Expanded(
            child: StreamBuilder<List<Amende>>(
              key: _streamKey, // Clé unique pour forcer le rebuild
              stream: service.streamMyAmendes(),
              builder: (context, snapshot) {
                print(
                    '🔵 StreamBuilder rebuild - connectionState: ${snapshot.connectionState}');
                print(
                    '🔵 Has data: ${snapshot.hasData}, Data length: ${snapshot.data?.length}');

                // État de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Erreur
                if (snapshot.hasError) {
                  print('❌ StreamBuilder error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshStream,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final amendes = snapshot.data ?? [];
                print('✅ Affichage de ${amendes.length} amendes');

                // Aucune amende
                if (amendes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune amende pour l\'instant',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Appuyez sur + pour en ajouter une',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                // Liste des amendes
                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: amendes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final amende = amendes[index];
                    final euros =
                        (amende.montantCentimes / 100).toStringAsFixed(2);

                    // Couleur selon le statut
                    Color statusColor;
                    IconData statusIcon;
                    switch (amende.statut) {
                      case 'payee':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        break;
                      case 'majoree':
                        statusColor = Colors.red;
                        statusIcon = Icons.warning;
                        break;
                      default: // en_attente
                        statusColor = Colors.orange;
                        statusIcon = Icons.pending;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(statusIcon, color: statusColor),
                      ),
                      title: Text(
                        '${amende.type} · $euros €',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Statut: ${amende.statut} · Échéance: ${_formatDate(amende.dateLimite)}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'payee',
                            child: Text('Marquer payée'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Supprimer'),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'payee') {
                            await service.markPayee(amende.id);
                            _refreshStream();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Amende marquée comme payée'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else if (value == 'delete') {
                            // Demander confirmation
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmer la suppression'),
                                content: Text(
                                    'Supprimer l\'amende "${amende.type}" ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await service.deleteAmende(amende.id);
                              _refreshStream();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Amende supprimée'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      onTap: () {
                        // Afficher les détails dans un dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(amende.type),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Montant: $euros €'),
                                Text('Statut: ${amende.statut}'),
                                Text(
                                    'Date limite: ${_formatDate(amende.dateLimite)}'),
                                if (amende.numeroTelepaiement != null)
                                  Text(
                                      'N° télépaiement: ${amende.numeroTelepaiement}'),
                                if (amende.cle != null)
                                  Text('Clé: ${amende.cle}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
