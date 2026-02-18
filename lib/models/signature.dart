import 'package:cloud_firestore/cloud_firestore.dart';

class Signature {
  final String deviceId;
  final DateTime startDate;
  final DateTime endDate;
  final String? lastKeyUsed;
  final bool isActive;

  Signature({
    required this.deviceId,
    required this.startDate,
    required this.endDate,
    this.lastKeyUsed,
    required this.isActive,
  });

  // Verifica se a assinatura expirou comparando com a data atual
  bool get isExpired => DateTime.now().isAfter(endDate);

  // Converte DocumentSnapshot do Firebase para a Classe
  factory Signature.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Signature(
      deviceId: data['deviceId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      lastKeyUsed: data['lastKeyUsed'],
      isActive: data['status'] == 'active',
    );
  }

  // Converte de Map (SharedPreferences/Cache) para a Classe
  factory Signature.fromMap(Map<String, dynamic> map) {
    return Signature(
      deviceId: map['deviceId'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      lastKeyUsed: map['lastKeyUsed'],
      isActive: map['isActive'] == 1 || map['isActive'] == true,
    );
  }

  // Converte a Classe para Map (Salvar no Firebase ou Local)
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'lastKeyUsed': lastKeyUsed,
      'isActive': isActive,
    };
  }

  // Para salvar no Firestore usamos Timestamps
  Map<String, dynamic> toFirestore() {
    return {
      'deviceId': deviceId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'lastKeyUsed': lastKeyUsed,
      'status': isActive ? 'active' : 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
