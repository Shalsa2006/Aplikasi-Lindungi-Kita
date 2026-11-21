import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

class PanduanTab extends StatefulWidget {
  const PanduanTab({super.key});
  @override
  State<PanduanTab> createState() => _PanduanTabState();
}

class _PanduanTabState extends State<PanduanTab> {
  late Future<dynamic> _res = Api.get('/resources');

  static const _panduan = [
    ('Hak-hak korban', Icons.balance_rounded, C.purple,
        '• Hak atas penanganan, perlindungan, dan pemulihan.\n• Hak atas pendampingan hukum, psikologis, dan medis.\n• Hak untuk dirahasiakan identitasnya.\n• Hak untuk tidak disalahkan (victim blaming).\n\nDasar hukum antara lain UU No. 12 Tahun 2022 (TPKS), UU No. 23 Tahun 2004 (PKDRT), dan Permendikbudristek No. 46 Tahun 2023 (pencegahan & penanganan kekerasan di satuan pendidikan). Informasi ini bukan nasihat hukum.'),
    ('Mengumpulkan bukti dengan aman', Icons.folder_zip_rounded, C.pink,
        '• Simpan tangkapan layar chat, foto luka, atau rekaman dengan tanggal.\n• Jangan hapus pesan asli.\n• Catat waktu, tempat, dan saksi.\n• Unggah ke LindungiKita agar tersimpan terenkripsi dengan hash keaslian.\n• Bila ada luka, segera periksa ke fasilitas kesehatan (visum).'),
    ('Kenali tanda-tandanya', Icons.visibility_rounded, C.coral,
        '• Perundungan: ejekan terus-menerus, dikucilkan, diperas, disebar aibnya.\n• Kekerasan seksual: sentuhan/ucapan seksual tanpa persetujuan, ancaman penyebaran foto.\n• KDRT: kekerasan fisik, psikis, ekonomi, atau penelantaran di rumah.\nKamu tidak salah, apa pun yang terjadi.'),
    ('Jika kamu dalam bahaya sekarang', Icons.emergency_rounded, C.red,
        '• Menjauh ke tempat ramai/aman.\n• Hubungi 110 (Polisi) atau 119 (medis).\n• Tekan tombol SOS di Beranda untuk mengirim lokasi ke kontak tepercaya.\n• Hubungi SAPA 129 untuk pendampingan.'),
  ];

  Future<void> _call(String kontak) async {
    final digits = kontak.replaceAll(RegExp(r'[^0-9+]'), '');
    try {
      await launchUrl(Uri(scheme: 'tel', path: digits));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan & Bantuan')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _res = Api.get('/resources')),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
          ..._panduan.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: p.$3.op(.12), blurRadius: 14, offset: const Offset(0, 6))]),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: p.$3.op(.14), borderRadius: BorderRadius.circular(12)), child: Icon(p.$2, color: p.$3)),
                      title: Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(p.$4, style: const TextStyle(height: 1.5, color: C.ink))],
                    ),
                  ),
                ),
              )),
          const SectionTitle('Lembaga bantuan'),
          FutureBuilder<dynamic>(
            future: _res,
            builder: (_, s) {
              if (s.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              if (s.hasError) return ErrorState(s.error.toString(), () => setState(() => _res = Api.get('/resources')));
              final list = s.data as List;
              return Column(
                children: list.map((e) {
                  final m = e as Map;
                  final darurat = m['kategori'] == 'Darurat';
                  final col = darurat ? C.red : C.teal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: col.op(.12), borderRadius: BorderRadius.circular(14)), child: Icon(darurat ? Icons.local_hospital_rounded : Icons.volunteer_activism_rounded, color: col)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m['nama'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                            if (m['deskripsi'] != null) Text(m['deskripsi'].toString(), style: const TextStyle(color: C.muted, fontSize: 12)),
                            Text(m['kontak'].toString(), style: TextStyle(color: col, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: col),
                          onPressed: () => _call(m['kontak'].toString()),
                          icon: const Icon(Icons.call_rounded, color: Colors.white),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }
}
