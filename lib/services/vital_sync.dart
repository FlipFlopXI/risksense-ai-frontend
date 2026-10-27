import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:medguide/services/api_client.dart';

/// Watches patient-owned vital records already ingested by the backend.
/// Device pairing and ingestion happen outside the mobile app.
class VitalSync extends ChangeNotifier {
  VitalSync._();
  static final instance = VitalSync._();

  Timer? _pollTimer;
  Timer? _playTimer;
  final List<Map<String, dynamic>> _pending = [];
  Set<String> _seen = {};
  String? _patientId;
  String? _userId;
  bool listening = false;
  bool receiving = false;
  bool busy = false;
  String? error;
  Map<String, dynamic>? current;
  DateTime? lastUpdated;
  bool get hasReceivedUpdate => lastUpdated != null && _receivedSinceStart;
  bool _receivedSinceStart = false;

  void ensureUser(String? userId) {
    if (_userId != null && _userId != userId) stop();
  }

  Future<void> start() async {
    if (listening || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final patient = Map<String, dynamic>.from(
          await ApiClient.instance.get('/patients/me'));
      final user =
          Map<String, dynamic>.from(await ApiClient.instance.get('/auth/me'));
      final id = patient['id']?.toString();
      if (id == null) throw StateError('Patient profile unavailable.');
      final records = await _read();
      if (_patientId != id) {
        current = null;
        lastUpdated = null;
      }
      _patientId = id;
      _userId = user['id']?.toString();
      _receivedSinceStart = false;
      _seen = records.map((r) => r['id'].toString()).toSet();
      if (records.isNotEmpty) {
        current = records.first;
        lastUpdated =
            DateTime.tryParse(records.first['recorded_at']?.toString() ?? '')
                ?.toLocal();
      }
      listening = true;
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => poll());
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not read patient vitals.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _read() async =>
      (await ApiClient.instance.get('/health/vitals/', query: {'limit': 100})
              as List)
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();

  bool _polling = false;
  Future<void> poll() async {
    if (!listening || _polling) return;
    _polling = true;
    try {
      final records = await _read();
      final arrivals = records
          .where((r) => !_seen.contains(r['id'].toString()))
          .toList()
          .reversed;
      _seen.addAll(records.map((r) => r['id'].toString()));
      _pending.addAll(arrivals);
      error = null;
      if (_pending.isNotEmpty && _playTimer == null) _playNext();
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        stop();
        return;
      }
      error = e is ApiException ? e.message : 'Vital updates are unavailable.';
      notifyListeners();
    } finally {
      _polling = false;
    }
  }

  void _playNext() {
    if (!listening || _pending.isEmpty) {
      receiving = false;
      _playTimer = null;
      notifyListeners();
      return;
    }
    receiving = true;
    _receivedSinceStart = true;
    current = _pending.removeAt(0);
    lastUpdated =
        DateTime.tryParse(current?['recorded_at']?.toString() ?? '')?.toLocal();
    notifyListeners();
    _playTimer = Timer(const Duration(milliseconds: 1100), () {
      _playTimer = null;
      _playNext();
    });
  }

  void stop() {
    _pollTimer?.cancel();
    _playTimer?.cancel();
    _pollTimer = null;
    _playTimer = null;
    _pending.clear();
    listening = false;
    receiving = false;
    _receivedSinceStart = false;
    error = null;
    notifyListeners();
  }
}
