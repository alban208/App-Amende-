// lib/models/amende.dart
class Amende {
  final String id;
  final String userId;
  final String type;           // "Radar" | "Stationnement" | "Autre"
  final int montantCentimes;   // 9000 => 90.00€
  final DateTime dateLimite;   // pour rappels
  final String statut;         // "en_attente" | "payee" | "majoree"
  final String? numeroTelepaiement;
  final String? cle;
  final String? imageUrl;
  final DateTime createdAt;

  Amende({
    required this.id,
    required this.userId,
    required this.type,
    required this.montantCentimes,
    required this.dateLimite,
    required this.statut,
    this.numeroTelepaiement,
    this.cle,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type,
    'montantCentimes': montantCentimes,
    'dateLimite': dateLimite.toIso8601String(),
    'statut': statut,
    'numeroTelepaiement': numeroTelepaiement,
    'cle': cle,
    'imageUrl': imageUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Amende.fromDoc(String id, Map<String, dynamic> m) => Amende(
    id: id,
    userId: m['userId'] as String,
    type: m['type'] as String,
    montantCentimes: m['montantCentimes'] as int,
    dateLimite: DateTime.parse(m['dateLimite'] as String),
    statut: m['statut'] as String,
    numeroTelepaiement: m['numeroTelepaiement'] as String?,
    cle: m['cle'] as String?,
    imageUrl: m['imageUrl'] as String?,
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}
