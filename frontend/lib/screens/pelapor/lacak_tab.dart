import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../shared/case_detail.dart';

class LacakTab extends StatefulWidget {
  final bool guest;
  const LacakTab({super.key, required this.guest});
  @override
  State<LacakTab> createState() => _LacakTabState();
}

class _LacakTabState extends State<LacakTab> {
  final _no = TextEditingController();
  final _code = TextEditingController();
  Future<dynamic>? _mine;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSession);
    _loadMine();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    session.removeListener(_onSession);
    super.dispose();
  }

  void _loadMine() {
    if (!widget.guest && session.loggedIn && session.role == 'pelapor') {
      _mine = Api.get('/my-reports');
    }
  }

  void _open() {
    if (_no.text.trim().isEmpty || _code.text.trim().isEmpty) return toast(context, 'Isi nomor kasus dan kode akses', error: true);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(mode: CaseMode.guest, caseNo: _no.text.trim(), code: _code.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    final saved = session.saved;
    return Scaffold(
      appBar: AppBar(title: const Text('Lacak Kasus')),
      body: RefreshIndicator(
        onRefresh: () async => setState(_loadMine),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Punya nomor kasus?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const Text('Masukkan nomor kasus & kode akses dari laporanmu.', style: TextStyle(color: C.muted)),
              const SizedBox(height: 14),
              TextField(controller: _no, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Nomor kasus (LK-......)', prefixIcon: Icon(Icons.confirmation_number_rounded))),
              const SizedBox(height: 10),
              TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Kode akses (XXXX-XXXX)', prefixIcon: Icon(Icons.key_rounded))),
              const SizedBox(height: 14),
              GradientButton(label: 'Cek status', icon: Icons.search_rounded, onPressed: _open),
            ]),
          ),
          if (saved.isNotEmpty) ...[
            const SectionTitle('Tersimpan di HP ini'),
            ...saved.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(mode: CaseMode.guest, caseNo: c['case_no'], code: c['code']))),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: C.purple.op(.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.folder_special_rounded, color: C.purple)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c['case_no'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(c['judul'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12.5)),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: C.muted),
                        onPressed: () async {
                          if (await confirm(context, 'Hapus dari HP?', 'Nomor kasus dan kode akan dihapus dari perangkat ini (laporan di server tetap ada). Pastikan sudah kamu catat.', ok: 'Hapus')) {
                            session.removeCase(c['case_no']);
                          }
                        },
                      ),
                    ]),
                  ),
                )),
          ],
          if (_mine != null) ...[
            const SectionTitle('Laporan bernama saya'),
            FutureBuilder<dynamic>(
              future: _mine,
              builder: (_, s) {
                if (s.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                if (s.hasError) return Text(s.error.toString(), style: const TextStyle(color: C.muted));
                final list = s.data as List;
                if (list.isEmpty) return const SoftCard(child: Text('Belum ada laporan bernama. Laporan anonim muncul di daftar "Tersimpan di HP ini".', style: TextStyle(color: C.muted)));
                return Column(
                  children: list.map((e) {
                    final m = Map<String, dynamic>.from(e as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(mode: CaseMode.owner, id: int.parse(m['id'].toString())))),
                        child: Row(children: [
                          Icon(katOf(m['kategori']).icon, color: katOf(m['kategori']).color),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m['judul'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text('${m['case_no']} • ${fmtDate(m['created_at'], time: false)}', style: const TextStyle(color: C.muted, fontSize: 12)),
                          ])),
                          Pill(statusLabel(m['status']), statusColor(m['status'])),
                        ]),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ]),
      ),
    );
  }
}
