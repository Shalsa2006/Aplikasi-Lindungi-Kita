import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

String _waNumber(String hp) {
  var n = hp.replaceAll(RegExp(r'[^0-9+]'), '');
  if (n.startsWith('+')) return n.substring(1);
  if (n.startsWith('0')) return '62${n.substring(1)}';
  return n;
}

Future<void> _open(Uri u) async {
  try {
    await launchUrl(u, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Tombol darurat: catat kejadian di server + kirim lokasi ke kontak tepercaya (WhatsApp / SMS).
Future<void> triggerSos(BuildContext context) async {
  if (!session.loggedIn || session.role != 'pelapor') {
    toast(context, 'Masuk dulu agar SOS bisa mengirim lokasi ke kontak tepercayamu.', error: true);
    return;
  }
  final ok = await confirm(context, 'Kirim sinyal darurat?', 'Lokasimu akan dicatat dan siap dikirim ke kontak tepercaya.', ok: 'Kirim SOS');
  if (!ok || !context.mounted) return;

  double? lat, lng;
  try {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 8));
      lat = pos.latitude;
      lng = pos.longitude;
    }
  } catch (_) {}

  try {
    final d = await Api.post('/sos', {'lat': lat, 'lng': lng});
    if (!context.mounted) return;
    final kontak = (d['kontak'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final peta = d['peta'] as String?;
    final teks = '🚨 DARURAT (LindungiKita): saya butuh bantuan sekarang.${peta != null ? ' Lokasi saya: $peta' : ''}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(gradient: gSos, shape: BoxShape.circle), child: const Icon(Icons.sos_rounded, color: Colors.white)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Sinyal darurat tercatat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
          ]),
          const SizedBox(height: 6),
          Text(lat != null ? 'Lokasi berhasil didapat. Kirim ke kontak tepercayamu:' : 'Lokasi tidak tersedia (izin GPS belum diberikan). Kamu tetap bisa mengirim pesan.', style: const TextStyle(color: C.muted)),
          const SizedBox(height: 12),
          if (kontak.isEmpty)
            const Text('Kamu belum punya kontak tepercaya. Tambahkan di menu Akun.', style: TextStyle(fontWeight: FontWeight.w700))
          else
            ...kontak.map((k) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const CircleAvatar(backgroundColor: C.bg, child: Icon(Icons.person_rounded, color: C.purple)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(k['nama'].toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                    IconButton(
                      tooltip: 'WhatsApp',
                      onPressed: () => _open(Uri.parse('https://wa.me/${_waNumber(k['no_hp'].toString())}?text=${Uri.encodeComponent(teks)}')),
                      icon: const Icon(Icons.chat_rounded, color: C.green),
                    ),
                    IconButton(
                      tooltip: 'SMS',
                      onPressed: () => _open(Uri(scheme: 'sms', path: k['no_hp'].toString(), queryParameters: {'body': teks})),
                      icon: const Icon(Icons.sms_rounded, color: C.blue),
                    ),
                  ]),
                )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: C.red, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => _open(Uri(scheme: 'tel', path: '110')),
              icon: const Icon(Icons.local_police_rounded),
              label: const Text('Telepon Polisi 110', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
  }
}
