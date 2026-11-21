import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/logo.dart';
import 'sos.dart';

class BerandaTab extends StatefulWidget {
  final bool guest;
  final void Function(int) onGo;
  const BerandaTab({super.key, required this.guest, required this.onGo});
  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  late Future<dynamic> _stats = Api.get('/stats/public');

  Future<void> _refresh() async {
    setState(() => _stats = Api.get('/stats/public'));
    try {
      await _stats;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.guest || !session.loggedIn ? 'Sahabat' : session.nama.split(' ').first;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: EdgeInsets.zero, children: [
        GradientHeader(
          gradient: gMain,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const LogoFull(size: 38, onDark: true),
              const Spacer(),
              if (widget.guest)
                Pill('Mode anonim', Colors.white, icon: Icons.visibility_off_rounded)
              else
                Pill('Pelapor', Colors.white, icon: Icons.verified_user_rounded),
            ]),
            const SizedBox(height: 22),
            Text('Halo, $nama 👋', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Kamu tidak sendirian. Ceritamu aman bersama kami.', style: TextStyle(color: Colors.white70, fontSize: 14.5)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => widget.onGo(1),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(gradient: gMain, shape: BoxShape.circle), child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28)),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Buat laporan baru', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.ink)),
                      Text('Anonim, tanpa perlu akun', style: TextStyle(color: C.muted, fontSize: 12.5)),
                    ]),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: C.muted),
                ]),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('Butuh bantuan segera?'),
            GestureDetector(
              onTap: () => triggerSos(context),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: gSos, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: C.red.op(.35), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Row(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.op(.25), border: Border.all(color: Colors.white, width: 3)),
                    child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tombol Darurat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      Text('Kirim lokasimu ke kontak tepercaya', style: TextStyle(color: Colors.white70)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SectionTitle('Menu cepat'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _quick('Lacak Kasus', 'Pantau status', Icons.manage_search_rounded, C.blue, () => widget.onGo(2)),
                _quick('Chat Aman', 'Dengan pendamping', Icons.forum_rounded, C.teal, () => widget.onGo(2)),
                _quick('Hak Korban', 'Kenali hakmu', Icons.balance_rounded, C.coral, () => widget.onGo(3)),
                _quick('Lembaga Bantuan', 'Hubungi langsung', Icons.volunteer_activism_rounded, C.pink, () => widget.onGo(3)),
              ],
            ),
            const SectionTitle('Jenis laporan yang bisa kamu buat'),
            SizedBox(
              height: 112,
              child: ListView(scrollDirection: Axis.horizontal, children: kKategori.map((k) {
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [k.color, k.color.op(.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(k.icon, color: Colors.white, size: 30),
                    Text(k.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ]),
                );
              }).toList()),
            ),
            const SectionTitle('Gambaran kasus (data agregat)'),
            FutureBuilder<dynamic>(
              future: _stats,
              builder: (_, s) {
                if (s.connectionState != ConnectionState.done) return const SoftCard(child: Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())));
                if (s.hasError) {
                  return SoftCard(child: Row(children: [
                    const Icon(Icons.cloud_off_rounded, color: C.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.error.toString(), style: const TextStyle(color: C.muted, fontSize: 12.5))),
                  ]));
                }
                final d = s.data as Map;
                final kat = (d['per_kategori'] as List).map((e) => MapEntry(katOf(e['kategori']).label, int.parse(e['jumlah'].toString()))).toList();
                final wil = (d['per_wilayah'] as List).map((e) => MapEntry(e['wilayah'].toString(), int.parse(e['jumlah'].toString()))).toList();
                return Column(children: [
                  Row(children: [
                    Expanded(child: StatTile('Total laporan', '${d['total']}', Icons.inbox_rounded, C.purple)),
                    const SizedBox(width: 12),
                    Expanded(child: StatTile('Selesai ditangani', '${d['selesai']}', Icons.task_alt_rounded, C.green)),
                  ]),
                  const SizedBox(height: 12),
                  SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Per jenis', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    BarList(items: kat, color: C.pink),
                  ])),
                  const SizedBox(height: 12),
                  SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Sebaran wilayah', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    BarList(items: wil, color: C.teal),
                    const SizedBox(height: 6),
                    const Text('Data diagregasi, tanpa identitas.', style: TextStyle(fontSize: 11.5, color: C.muted)),
                  ])),
                ]);
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _quick(String t, String s, IconData i, Color c, VoidCallback onTap) => SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.op(.14), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 22)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: C.ink)),
            Text(s, style: const TextStyle(color: C.muted, fontSize: 11.5)),
          ]),
        ]),
      );
}
