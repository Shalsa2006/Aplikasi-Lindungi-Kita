import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

/// Status login + data lokal (kasus anonim yang disimpan di HP).
class Session extends ChangeNotifier {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> saved = [];
  bool ready = false;

  String? get role => user?['role'] as String?;
  String get nama => (user?['nama'] ?? '') as String;
  bool get loggedIn => user != null && Api.token != null;

  /// Kasus tersimpan dipisah per akun, supaya akun lain di HP yang sama tidak bisa melihatnya.
  String get _casesKey => 'cases_${user?['id'] ?? 'tamu'}';

  Future<void> _loadSaved(SharedPreferences p) async {
    final s = p.getString(_casesKey);
    if (s == null) {
      saved = [];
    } else {
      saved = (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    Api.baseUrl = p.getString('base') ?? Api.baseUrl;
    Api.token = p.getString('token');
    final u = p.getString('user');
    if (u != null) user = Map<String, dynamic>.from(jsonDecode(u));
    if (Api.token != null) {
      try {
        final me = await Api.get('/me');
        user = Map<String, dynamic>.from(me);
        await p.setString('user', jsonEncode(user));
      } on ApiException catch (e) {
        if (e.status == 401 || e.status == 403) await _clear(p);
      }
    }
    await p.remove('cases'); // daftar lama (bersama) dihapus
    await _loadSaved(p);
    ready = true;
    notifyListeners();
  }

  Future<void> _setAuth(dynamic data) async {
    final p = await SharedPreferences.getInstance();
    Api.token = data['token'] as String;
    user = Map<String, dynamic>.from(data['user']);
    await p.setString('token', Api.token!);
    await p.setString('user', jsonEncode(user));
    await _loadSaved(p);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final d = await Api.post('/auth/login', {'email': email, 'password': password});
    await _setAuth(d);
  }

  Future<void> register(String nama, String email, String hp, String password) async {
    final d = await Api.post('/auth/register', {'nama': nama, 'email': email, 'no_hp': hp, 'password': password});
    await _setAuth(d);
  }

  Future<void> _clear(SharedPreferences p) async {
    Api.token = null;
    user = null;
    await p.remove('token');
    await p.remove('user');
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await _clear(p);
    await _loadSaved(p); // kembali ke daftar mode tamu
    notifyListeners();
  }

  Future<void> setBase(String url) async {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    Api.baseUrl = u;
    final p = await SharedPreferences.getInstance();
    await p.setString('base', u);
    notifyListeners();
  }

  Future<void> saveCase(String caseNo, String code, String judul) async {
    saved.removeWhere((c) => c['case_no'] == caseNo);
    saved.insert(0, {'case_no': caseNo, 'code': code, 'judul': judul});
    final p = await SharedPreferences.getInstance();
    await p.setString(_casesKey, jsonEncode(saved));
    notifyListeners();
  }

  Future<void> removeCase(String caseNo) async {
    saved.removeWhere((c) => c['case_no'] == caseNo);
    final p = await SharedPreferences.getInstance();
    await p.setString(_casesKey, jsonEncode(saved));
    notifyListeners();
  }
}

final Session session = Session();