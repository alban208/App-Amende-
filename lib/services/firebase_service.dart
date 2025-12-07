import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/amende.dart';
import 'dart:typed_data'; // Pour Uint8List

/// Service centralisé pour toutes les interactions Firebase
/// Gère : Auth, Firestore, Storage
class FirebaseService {
  // Singleton pattern pour avoir une seule instance
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();
  
  // Instances Firebase
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  
  // Référence à la collection 'amendes'
  CollectionReference<Map<String, dynamic>> get _amendesCol =>
      _db.collection('amendes');
  
  /// ============================================
  /// AUTHENTIFICATION
  /// ============================================
  
  /// Stream de l'état d'authentification
  Stream<User?> authStateChanges() => _auth.authStateChanges();
  
  /// Utilisateur actuellement connecté (ou null)
  User? get currentUser => _auth.currentUser;
  
  /// Inscription avec email/mot de passe
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  /// Connexion avec email/mot de passe
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  /// Déconnexion
  Future<void> signOut() async => await _auth.signOut();
  
  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  /// ============================================
  /// GESTION DES AMENDES (FIRESTORE)
  /// ============================================
  
  /// Stream temps réel des amendes de l'utilisateur connecté
  /// Triées par date de création (plus récentes d'abord)
  Stream<List<Amende>> streamMyAmendes() {
    final uid = currentUser!.uid;
    
    return _amendesCol
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Amende.fromDoc(doc.id, doc.data()))
              .toList();
        });
  }
  
  /// Stream des amendes par statut
  Stream<List<Amende>> streamAmendesByStatut(String statut) {
    final uid = currentUser!.uid;
    
    return _amendesCol
        .where('userId', isEqualTo: uid)
        .where('statut', isEqualTo: statut)
        .orderBy('dateLimite', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Amende.fromDoc(doc.id, doc.data()))
              .toList();
        });
  }
  
  /// Création d'une nouvelle amende
  /// Retourne l'ID du document créé
  Future<String> createAmende({
    required String type,
    required int montantCentimes,
    required DateTime dateLimite,
    String statut = 'en_attente',
    String? numeroTelepaiement,
    String? cle,
    String? imageUrl,
  }) async {
    final uid = currentUser!.uid;
    final now = DateTime.now();
    
    final docRef = await _amendesCol.add({
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
    
    return docRef.id;
  }
  
  /// Récupérer une amende par son ID
  Future<Amende?> getAmende(String id) async {
    final doc = await _amendesCol.doc(id).get();
    if (!doc.exists) return null;
    return Amende.fromDoc(doc.id, doc.data()!);
  }
  
  /// Marquer une amende comme payée
  Future<void> markPayee(String amendeId) async {
    await _amendesCol.doc(amendeId).update({
      'statut': 'payee',
    });
  }
  
  /// Marquer une amende comme majorée
  Future<void> markMajoree(String amendeId) async {
    await _amendesCol.doc(amendeId).update({
      'statut': 'majoree',
    });
  }
  
  /// Mettre à jour une amende
  Future<void> updateAmende(String amendeId, Map<String, dynamic> data) async {
    await _amendesCol.doc(amendeId).update(data);
  }
  
  /// Supprimer une amende
  Future<void> deleteAmende(String amendeId) async {
    final doc = await _amendesCol.doc(amendeId).get();
    if (doc.exists) {
      final data = doc.data()!;
      // Supprimer l'image associée si elle existe
      if (data['imageUrl'] != null) {
        try {
          final ref = _storage.refFromURL(data['imageUrl']);
          await ref.delete();
        } catch (e) {
          print('Erreur suppression image : $e');
        }
      }
    }
    await _amendesCol.doc(amendeId).delete();
  }
  
  /// ============================================
  /// STATISTIQUES
  /// ============================================
  
  /// Calculer le total des amendes (en centimes)
  Future<int> getTotalAmendes({String? statut}) async {
    final uid = currentUser!.uid;
    
    Query query = _amendesCol.where('userId', isEqualTo: uid);
    
    if (statut != null) {
      query = query.where('statut', isEqualTo: statut);
    }
    
    final snapshot = await query.get();
    
    int total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['montantCentimes'] as int);
    }
    
    return total;
  }
  
  /// Compter le nombre d'amendes par statut
  Future<Map<String, int>> getAmendesCountByStatut() async {
    final uid = currentUser!.uid;
    
    final snapshot = await _amendesCol
        .where('userId', isEqualTo: uid)
        .get();
    
    final counts = <String, int>{
      'en_attente': 0,
      'payee': 0,
      'majoree': 0,
    };
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final statut = data['statut'] as String;
      counts[statut] = (counts[statut] ?? 0) + 1;
    }
    
    return counts;
  }
  
  /// ============================================
  /// STORAGE (Upload d'images)
  /// ============================================
  
  /// Upload une image de scan d'amende
  /// Retourne l'URL de téléchargement
  Future<String> uploadAmendeImage(String amendeId, List<int> imageBytes) async {
    final uid = currentUser!.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Chemin : users/{uid}/amendes/{amendeId}_{timestamp}.jpg
    final ref = _storage
        .ref()
        .child('users')
        .child(uid)
        .child('amendes')
        .child('${amendeId}_$timestamp.jpg');
    
    // Upload
    await ref.putData(
      Uint8List.fromList(imageBytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    // Récupérer l'URL publique
    return await ref.getDownloadURL();
  }
  
  /// Supprimer une image depuis son URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
    print('Erreur suppression image : $e');
    }
  }
}