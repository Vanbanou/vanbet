import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanbet/models/signature.dart';

class SignatureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _storageKey = 'user_signature';
  static const String _lastDateKey = 'last_known_date';
  static const String _lastSyncKey = 'last_sync_online';

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) return (await deviceInfo.androidInfo).id;
    if (Platform.isIOS) {
      return (await deviceInfo.iosInfo).identifierForVendor ?? "unknown";
    }
    return "unknown";
  }

  // Verificação rápida (Síncrona/Cache) para não travar o carregamento inicial
  Future<bool> fastCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final int nowLocal = DateTime.now().millisecondsSinceEpoch;
    final int lastKnown = prefs.getInt(_lastDateKey) ?? 0;

    if (nowLocal < lastKnown) return false; // Bloqueia se recuou o relógio

    final String? cachedData = prefs.getString(_storageKey);
    if (cachedData == null) return false;

    final signature = Signature.fromMap(jsonDecode(cachedData));
    return !signature.isExpired && signature.isActive;
  }

  // Sincronização em background (executada após o app abrir)
  Future<void> syncSubscriptionInBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final int now = DateTime.now().millisecondsSinceEpoch;

    // Só tenta validar no Firebase se houver internet e a cada 10 dias (opcional) ou se o lastSync for antigo
    // Para validar a cada 10 dias use: if (now - lastSync < 864000000) return;

    try {
      final String id = await getDeviceId();
      DocumentSnapshot doc = await _firestore
          .collection('subscriptions')
          .doc(id)
          .get(const GetOptions(source: Source.server));

      if (doc.exists) {
        final signature = Signature.fromFirestore(doc);

        // Se a data do servidor for diferente da local (devido ao avanço de data offline),
        // o servidor é a verdade absoluta.
        await prefs.setString(_storageKey, jsonEncode(signature.toMap()));
        await prefs.setInt(_lastDateKey, now);
        await prefs.setInt(_lastSyncKey, now);
      }
    } catch (e) {
      // Falha silenciosa (sem internet) - mantém o cache atualizado com o tempo local
      await prefs.setInt(_lastDateKey, now);
    }
  }

  Future<bool> activateKey(String key) async {
    try {
      final String id = await getDeviceId();
      final keyRef = _firestore.collection('keys').doc(key);
      final keyDoc = await keyRef.get();

      if (!keyDoc.exists || keyDoc.data()?['used'] == true) return false;

      final DateTime now = DateTime.now();
      final DateTime expiry = now.add(const Duration(days: 90));

      final newSignature = Signature(
        deviceId: id,
        startDate: now,
        endDate: expiry,
        lastKeyUsed: key,
        isActive: true,
      );

      await _firestore.runTransaction((transaction) async {
        transaction.update(keyRef, {
          'used': true,
          'usedBy': id,
          'usedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(
          _firestore.collection('subscriptions').doc(id),
          newSignature.toFirestore(),
        );
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(newSignature.toMap()));
      await prefs.setInt(_lastDateKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Signature?> getLocalSignature() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_storageKey);
    if (cachedData != null) return Signature.fromMap(jsonDecode(cachedData));
    return null;
  }
}
