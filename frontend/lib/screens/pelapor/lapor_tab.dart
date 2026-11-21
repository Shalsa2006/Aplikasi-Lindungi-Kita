import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../shared/case_detail.dart';

class LaporTab extends StatefulWidget {
  final bool guest;
  final void Function(int) onGo;
  const LaporTab({super.key, required this.guest, required this.onGo});
  @override
  State<LaporTab> createState() => _LaporTabState();
}

class _LaporTabState extends State<LaporTab> {
  String _kat = 'perundungan';
  final _judul = TextEditingController();
  final _desk = TextEditingController();
  final _lokasi = TextEditingController();
  String? _wilayah;
  DateTime? _tgl;
  bool _anonim = true;
  bool _loading = false;
  final List<PlatformFile> _files = [];

  bool get _canNamed => !widget.guest && session.loggedIn;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tgl ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Kapan kejadiannya?',
    );
    if (d != null) setState(() => _tgl = d);
  }

  Future<void> _pickFiles() async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
    if (r == null) return;
    setState(() {
      for (final f in r.files) {
        if (f.path != null && _files.length < 8) _files.add(f);
      }
    });
  }

  Future<void> _submit() async {
    if (_judul.text.trim().isEmpty) return toast(context, 'Judul singkat wajib diisi', error: true);
    if (_desk.text.trim().length < 10) return toast(context, 'Ceritakan kronologi sedikit lebih lengkap (min. 10 karakter)', error: true);
    setState(() => _loading = true);
    try {
      final tgl = _tgl == null ? '' : '${_tgl!.year}-${_tgl!.month.toString().padLeft(2, '0')}-${_tgl!.day.toString().padLeft(2, '0')}';
      final d = await Api.multipart(
        '/reports',
        {
          'kategori': _kat,
          'judul': _judul.text.trim(),
          'deskripsi': _desk.text.trim(),
          'lokasi': _lokasi.text.trim(),
          'wilayah': _wilayah ?? '',
          'tanggal_kejadian': tgl,
          'anonim': (_canNamed ? _anonim : true) ? '1' : '0',
        },
        _files.map((f) => f.path!).toList(),
      );
      final caseNo = d['case_no'] as String;
      final code = d['access_code'] as String;
      await session.saveCase(caseNo, code, _judul.text.trim());
      if (!mounted) return;
      final urg = d['urgensi'] as String;
      final n = d['bukti_tersimpan'];
      _reset();
      Navigator.push(context, MaterialPageRoute(builder: (_) => _SuksesScreen(caseNo: caseNo, code: code, urgensi: urg, bukti: n)));
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _judul.clear();
    _desk.clear();
    _lokasi.clear();
    setState(() {
      _wilayah = null;
      _tgl = null;
      _files.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = katOf(_kat);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEFE7FF), Color(0xFFFFE8F0)]), borderRadius: BorderRadius.circular(18)),
          child: const Row(children: [
            Icon(Icons.lock_rounded, color: C.purple),
            SizedBox(width: 10),
            Expanded(child: Text('Laporanmu dienkripsi. Ceritakan sebisamu — kamu boleh melewatkan bagian yang tidak nyaman.', style: TextStyle(fontSize: 13, height: 1.35))),
          ]),
        ),
        const SectionTitle('1. Jenis kejadian'),
        Wrap(spacing: 10, runSpacing: 10, children: kKategori.map((e) {
          final sel = e.key == _kat;
          return GestureDetector(
            onTap: () => setState(() => _kat = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? e.color : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: sel ? e.color : C.line, width: 1.5),
                boxShadow: sel ? [BoxShadow(color: e.color.op(.35), blurRadius: 12, offset: const Offset(0, 6))] : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.icon, size: 20, color: sel ? Colors.white : e.color),
                const SizedBox(width: 8),
                Text(e.label, style: TextStyle(fontWeight: FontWeight.w800, color: sel ? Colors.white : C.ink)),
              ]),
            ),
          );
        }).toList()),
        const SectionTitle('2. Ceritakan kejadiannya'),
        TextField(controller: _judul, decoration: InputDecoration(labelText: 'Judul singkat', prefixIcon: Icon(k.icon, color: k.color))),
        const SizedBox(height: 12),
        TextField(controller: _desk, minLines: 5, maxLines: 10, decoration: const InputDecoration(labelText: 'Kronologi (apa, siapa, di mana, kapan)', alignLabelWithHint: true)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Tanggal kejadian', prefixIcon: Icon(Icons.event_rounded)),
            child: Text(_tgl == null ? 'Pilih tanggal (opsional)' : fmtDate(_tgl!.toIso8601String(), time: false), style: TextStyle(color: _tgl == null ? C.muted : C.ink)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _lokasi, decoration: const InputDecoration(labelText: 'Lokasi kejadian (opsional)', prefixIcon: Icon(Icons.place_rounded))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _wilayah,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Provinsi (untuk statistik)', prefixIcon: Icon(Icons.map_rounded)),
          items: kWilayah.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
          onChanged: (v) => setState(() => _wilayah = v),
        ),
        const SectionTitle('3. Bukti (opsional)'),
        SoftCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Foto, dokumen, atau rekaman. Setiap berkas dienkripsi AES-256, diberi stempel waktu & hash SHA-256 agar keasliannya terjaga.', style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.35)),
            const SizedBox(height: 10),
            ..._files.asMap().entries.map((e) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file_rounded, color: C.purple),
                  title: Text(e.value.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${(e.value.size / 1024).toStringAsFixed(0)} KB'),
                  trailing: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _files.removeAt(e.key))),
                )),
            OutlinedButton.icon(
              onPressed: _files.length >= 8 ? null : _pickFiles,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(_files.isEmpty ? 'Pilih berkas' : 'Tambah berkas (${_files.length}/8)'),
            ),
          ]),
        ),
        const SectionTitle('4. Identitas'),
        SoftCard(
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _canNamed ? _anonim : true,
              activeColor: C.purple,
              onChanged: _canNamed ? (v) => setState(() => _anonim = v) : null,
              title: const Text('Laporkan secara anonim', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(_canNamed
                  ? (_anonim ? 'Identitasmu tidak dikaitkan dengan laporan.' : 'Laporan akan tertaut ke akunmu (petugas tetap tidak melihat namamu).')
                  : 'Tanpa akun, laporan selalu anonim. Kamu akan mendapat nomor kasus & kode akses.'),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        GradientButton(label: 'Kirim laporan', icon: Icons.send_rounded, loading: _loading, onPressed: _submit),
      ]),
    );
  }
}

class _SuksesScreen extends StatelessWidget {
  final String caseNo, code, urgensi;
  final dynamic bukti;
  const _SuksesScreen({required this.caseNo, required this.code, required this.urgensi, required this.bukti});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gMain),
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SizedBox(height: 10),
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 76),
            const SizedBox(height: 10),
            const Text('Laporan terkirim', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            const Text('Terima kasih sudah berani bersuara 💜', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 22),
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('NOMOR KASUS', style: TextStyle(color: C.muted, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 12)),
                SelectableText(caseNo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.purple, letterSpacing: 1)),
                const Divider(height: 28),
                const Text('KODE AKSES', style: TextStyle(color: C.muted, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 12)),
                SelectableText(code, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: C.pink, letterSpacing: 4)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.yellow.op(.25), borderRadius: BorderRadius.circular(14)),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_rounded, color: C.coral),
                    SizedBox(width: 8),
                    Expanded(child: Text('Catat kode ini! Hanya tampil sekali dan tidak bisa dipulihkan. Kode juga kami simpan di HP ini.', style: TextStyle(fontSize: 12.5))),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: 'Nomor kasus: $caseNo\nKode akses: $code'));
                        toast(context, 'Disalin ke papan klip');
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Salin'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  Pill('Urgensi awal: ${cap(urgensi)}', urgensiColor(urgensi), icon: Icons.flag_rounded),
                  Pill('$bukti bukti terenkripsi', C.green, icon: Icons.lock_rounded),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Lihat status kasus',
              icon: Icons.manage_search_rounded,
              gradient: const LinearGradient(colors: [C.teal, C.blue]),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(mode: CaseMode.guest, caseNo: caseNo, code: code))),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          ]),
        ),
      ),
    );
  }
}
