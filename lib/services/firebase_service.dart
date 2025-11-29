// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/amende.dart';

class FirebaseService {
  FirebaseService();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _amendesCol =>
      _db.collection('amendes');

  /// Stream temps réel des amendes de l'utilisateur connecté
  Stream<List<Amende>> streamMyAmendes() {
    final uid = _auth.currentUser!.uid;
    return _amendesCol
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Amende.fromDoc(d.id, d.data()))
            .toList());
  }

  /// Création d'une amende → retourne l'ID créé
  Future<String> createAmende({
    required String type,
    required int montantCentimes,
    required DateTime dateLimite,
    String statut = 'en_attente',
    String? numeroTelepaiement,
    String? cle,
    String? imageUrl,
  }) async {
    final uid = _auth.currentUser!.uid;
    final now = DateTime.now();
    final ref = await _amendesCol.add({
      'userId': uid,
      'type': type,
      'montantCentimes': montantCentimes,
      'dateLimite': dateLimite.toIso8601String(),
      'statut': statut,
      'numeroTelepaiement': numeroTelepaiement,
      'cle': cle,
      'imageUrl': imageUrl,
      'createdAt': now.toIso8601String(),
    });
    return ref.id;
  }

  /// Marquer payée
  Future<void> markPayee(String id) async {
    await _amendesCol.doc(id).update({'statut': 'payee'});
  }

  /// (optionnel) Récupérer une amende par ID
  Future<Amende?> getAmende(String id) async {
    final snap = await _amendesCol.doc(id).get();
    if (!snap.exists) return null;
    return Amende.fromDoc(snap.id, snap.data()!);
  }
}
