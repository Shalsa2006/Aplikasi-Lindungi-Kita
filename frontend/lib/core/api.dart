import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Klien REST API LindungiKita.
/// Alamat default cocok untuk emulator Android -> Laragon di PC yang sama.
/// (10.0.2.2 = "localhost" PC dilihat dari emulator). HP asli: pakai IP LAN PC, ubah lewat ikon gear di layar login.
class Api {
  static String baseUrl = 'http://10.0.2.2/lindungikita_api';
  static String? token;

  static Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Uri _uri(String path, [Map<String, String>? q]) {
    final u = Uri.parse('$baseUrl$path');
    if (q == null || q.isEmpty) return u;
    return u.replace(queryParameters: {...u.queryParameters, ...q});
  }

  static dynamic _parse(http.Response r) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw ApiException('Respons server tidak valid (${r.statusCode}). Cek alamat server dan pastikan Laragon menyala.', r.statusCode);
    }
    if (body is Map && body['ok'] == true) return body['data'];
    final msg = body is Map ? (body['message']?.toString() ?? 'Terjadi kesalahan') : 'Terjadi kesalahan';
    throw ApiException(msg, r.statusCode);
  }

  static Future<dynamic> _run(Future<http.Response> Function() f) async {
    try {
      final r = await f().timeout(const Duration(seconds: 30));
      return _parse(r);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server ($baseUrl). Pastikan Laragon (Apache & MySQL) menyala dan alamat server benar.');
    }
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _run(() => http.get(_uri(path, query), headers: _headers()));

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _run(() => http.post(_uri(path), headers: _headers(json: true), body: jsonEncode(body ?? {})));

  static Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _run(() => http.patch(_uri(path), headers: _headers(json: true), body: jsonEncode(body)));

  static Future<dynamic> delete(String path) =>
      _run(() => http.delete(_uri(path), headers: _headers()));

  /// Kirim form + banyak berkas (field `bukti[]`).
  static Future<dynamic> multipart(String path, Map<String, String> fields, List<String> files) => _run(() async {
        final req = http.MultipartRequest('POST', _uri(path));
        req.headers.addAll(_headers());
        req.fields.addAll(fields);
        for (final p in files) {
          req.files.add(await http.MultipartFile.fromPath('bukti[]', p));
        }
        final s = await req.send();
        return http.Response.fromStream(s);
      });

  /// Ambil berkas mentah (mis. bukti yang sudah didekripsi server).
  static Future<http.Response> getRaw(String path, {Map<String, String>? query}) async {
    try {
      final r = await http.get(_uri(path, query), headers: _headers()).timeout(const Duration(seconds: 40));
      if (r.statusCode >= 400) _parse(r);
      return r;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Gagal mengunduh berkas dari server.');
    }
  }
}
