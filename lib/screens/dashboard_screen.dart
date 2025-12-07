import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/amende.dart';
import '../services/firebase_service.dart';
import '../amende_form_screen.dart';
import 'amende_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser le singleton instance
    final service = FirebaseService.instance;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes amendes'),
        actions: [
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
          
          if (created == true && context.mounted) {
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
              stream: service.streamMyAmendes(),
              builder: (context, snapshot) {
                // État de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                // Erreur
                if (snapshot.hasError) {
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
                      ],
                    ),
                  );
                }
                
                final amendes = snapshot.data ?? [];
                
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Appuyez sur + pour en ajouter une',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    final euros = (amende.montantCentimes / 100).toStringAsFixed(2);
                    
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
                      default:
                        statusColor = Colors.orange;
                        statusIcon = Icons.pending;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                          ),
                        ),
                        
                        title: Text(
                          '${amende.type} · $euros €',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        
                        subtitle: Text(
                          'Statut: ${amende.statut} · Échéance: ${_formatDate(amende.dateLimite)}',
                        ),
                        
                        trailing: amende.statut == 'en_attente'
                            ? TextButton(
                                onPressed: () async {
                                  await FirebaseService.instance.markPayee(amende.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Amende marquée comme payée'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Marquer payée'),
                              )
                            : Icon(
                                Icons.check,
                                color: statusColor,
                              ),
                        
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AmendeDetailScreen(amende: amende),
                            ),
                          );
                        },
                      ),
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
  
  /// Formater une date en français
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}