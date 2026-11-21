import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../auth/server_dialog.dart';

class AkunTab extends StatefulWidget {
  final bool guest;
  const AkunTab({super.key, required this.guest});
  @override
  State<AkunTab> createState() => _AkunTabState();
}

class _AkunTabState extends State<AkunTab> {
  Future<dynamic>? _contacts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!widget.guest && session.loggedIn) _contacts = Api.get('/contacts');
  }

  Future<void> _add() async {
    final n = TextEditingController();
    final h = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Kontak tepercaya', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Nama')),
          const SizedBox(height: 10),
          TextField(controller: h, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. HP (08xx...)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.post('/contacts', {'nama': n.text, 'no_hp': h.text});
      if (mounted) setState(_load);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _logout() async {
    if (!await confirm(context, 'Keluar dari akun?', 'Kamu bisa masuk lagi kapan saja.', ok: 'Keluar')) return;
    await session.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        if (widget.guest || !session.loggedIn) ...[
          SoftCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Icon(Icons.visibility_off_rounded, size: 48, color: C.purple),
              const SizedBox(height: 10),
              const Text('Kamu sedang dalam mode anonim', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 4),
              const Text('Masuk untuk memakai tombol SOS, kontak tepercaya, dan laporan bernama.', textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
              const SizedBox(height: 16),
              GradientButton(label: 'Masuk', icon: Icons.login_rounded, onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false)),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Buat akun baru')),
            ]),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: gMain, borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Text(session.nama.isEmpty ? '?' : session.nama[0].toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.purple))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(session.nama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  Text((session.user?['email'] ?? '').toString(), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  const Pill('Pelapor', Colors.white, icon: Icons.person_rounded),
                ]),
              ),
            ]),
          ),
          SectionTitle('Kontak tepercaya (SOS)', trailing: TextButton.icon(onPressed: _add, icon: const Icon(Icons.add_rounded), label: const Text('Tambah'))),
          FutureBuilder<dynamic>(
            future: _contacts,
            builder: (_, s) {
              if (s.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              if (s.hasError) return Text(s.error.toString(), style: const TextStyle(color: C.muted));
              final l = s.data as List;
              if (l.isEmpty) return const SoftCard(child: Text('Belum ada kontak. Tambahkan 1–5 orang yang kamu percaya agar SOS bisa mengirim lokasimu.', style: TextStyle(color: C.muted)));
              return Column(
                children: l.map((e) {
                  final m = e as Map;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SoftCard(
                      child: Row(children: [
                        const CircleAvatar(backgroundColor: C.bg, child: Icon(Icons.favorite_rounded, color: C.pink)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['nama'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(m['no_hp'].toString(), style: const TextStyle(color: C.muted)),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: C.muted),
                          onPressed: () async {
                            await Api.delete('/contacts/${m['id']}');
                            if (mounted) setState(_load);
                          },
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
        const SectionTitle('Pengaturan'),
        SoftCard(
          onTap: () => showServerDialog(context),
          child: const Row(children: [
            Icon(Icons.settings_ethernet_rounded, color: C.purple),
            SizedBox(width: 12),
            Expanded(child: Text('Alamat server API', style: TextStyle(fontWeight: FontWeight.w800))),
            Icon(Icons.chevron_right_rounded),
          ]),
        ),
        if (!widget.guest && session.loggedIn) ...[
          const SizedBox(height: 10),
          SoftCard(
            onTap: _logout,
            child: const Row(children: [
              Icon(Icons.logout_rounded, color: C.red),
              SizedBox(width: 12),
              Expanded(child: Text('Keluar', style: TextStyle(fontWeight: FontWeight.w800, color: C.red))),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        const Center(child: Text('LindungiKita v1.0', style: TextStyle(color: C.muted, fontSize: 12))),
      ]),
    );
  }
}
