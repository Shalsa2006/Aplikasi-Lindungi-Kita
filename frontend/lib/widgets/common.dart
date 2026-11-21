import 'package:flutter/material.dart';
import '../core/theme.dart';

extension ColorOp on Color {
  Color op(double o) => withAlpha((o * 255).round());
}

void toast(BuildContext c, String m, {bool error = false}) {
  final sm = ScaffoldMessenger.of(c);
  sm.hideCurrentSnackBar();
  sm.showSnackBar(SnackBar(
    content: Text(m),
    backgroundColor: error ? C.red : C.ink,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ));
}

const _bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String fmtDate(dynamic s, {bool time = true}) {
  if (s == null) return '-';
  final d = DateTime.tryParse(s.toString().replaceFirst(' ', 'T'));
  if (d == null) return s.toString();
  final base = '${d.day} ${_bln[d.month - 1]} ${d.year}';
  if (!time) return base;
  return '$base, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class Kat {
  final String key, label;
  final IconData icon;
  final Color color;
  const Kat(this.key, this.label, this.icon, this.color);
}

const kKategori = [
  Kat('seksual', 'Kekerasan Seksual', Icons.health_and_safety_rounded, C.pink),
  Kat('kdrt', 'KDRT', Icons.home_rounded, C.coral),
  Kat('perundungan', 'Perundungan', Icons.groups_rounded, C.blue),
  Kat('lainnya', 'Lainnya', Icons.more_horiz_rounded, C.teal),
];

Kat katOf(String? k) => kKategori.firstWhere((e) => e.key == k, orElse: () => kKategori.last);

const kStatus = ['diterima', 'diverifikasi', 'ditangani', 'selesai'];
const kUrgensi = ['rendah', 'sedang', 'tinggi', 'kritis'];

Color statusColor(String? s) {
  switch (s) {
    case 'diverifikasi':
      return C.blue;
    case 'ditangani':
      return C.purple;
    case 'selesai':
      return C.green;
    default:
      return C.coral;
  }
}

Color urgensiColor(String? s) {
  switch (s) {
    case 'kritis':
      return C.red;
    case 'tinggi':
      return C.coral;
    case 'sedang':
      return C.blue;
    default:
      return C.green;
  }
}

String statusLabel(String? s) {
  switch (s) {
    case 'diterima':
      return 'Diterima';
    case 'diverifikasi':
      return 'Diverifikasi';
    case 'ditangani':
      return 'Sedang diproses';
    case 'selesai':
      return 'Selesai';
    default:
      return s == null || s.isEmpty ? '-' : s;
  }
}

String cap(String? s) => (s == null || s.isEmpty) ? '-' : s[0].toUpperCase() + s.substring(1);

const kWilayah = [
  'Aceh', 'Sumatera Utara', 'Sumatera Barat', 'Riau', 'Kepulauan Riau', 'Jambi', 'Sumatera Selatan',
  'Bangka Belitung', 'Bengkulu', 'Lampung', 'DKI Jakarta', 'Banten', 'Jawa Barat', 'Jawa Tengah',
  'DI Yogyakarta', 'Jawa Timur', 'Bali', 'Nusa Tenggara Barat', 'Nusa Tenggara Timur', 'Kalimantan Barat',
  'Kalimantan Tengah', 'Kalimantan Selatan', 'Kalimantan Timur', 'Kalimantan Utara', 'Sulawesi Utara',
  'Gorontalo', 'Sulawesi Tengah', 'Sulawesi Barat', 'Sulawesi Selatan', 'Sulawesi Tenggara', 'Maluku',
  'Maluku Utara', 'Papua', 'Papua Barat', 'Papua Selatan', 'Papua Tengah', 'Papua Pegunungan', 'Papua Barat Daya',
];

class GradientHeader extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  final EdgeInsets padding;
  const GradientHeader({super.key, required this.gradient, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 28)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(children: [
        Positioned(right: -30, top: -30, child: _Bubble(140, .10)),
        Positioned(left: -40, bottom: -50, child: _Bubble(150, .08)),
        Positioned(right: 60, bottom: 10, child: _Bubble(40, .12)),
        SafeArea(bottom: false, child: Padding(padding: padding, child: child)),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double d, o;
  const _Bubble(this.d, this.o);
  @override
  Widget build(BuildContext context) =>
      Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.op(o)));
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final Border? border;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color = Colors.white, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: border,
        boxShadow: [BoxShadow(color: C.purple.op(.08), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final LinearGradient gradient;
  const GradientButton({super.key, required this.label, this.icon, this.onPressed, this.loading = false, this.gradient = gMain});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return Opacity(
      opacity: disabled ? .6 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: gradient.colors.first.op(.35), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.op(.14), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.ink))),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const EmptyState(this.icon, this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(shape: BoxShape.circle, color: C.purple.op(.10)),
              child: Icon(icon, size: 44, color: C.purple),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.ink)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
          ]),
        ),
      );
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState(this.message, this.onRetry, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: C.muted),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba lagi')),
          ]),
        ),
      );
}

/// Batang horizontal sederhana untuk statistik.
class BarList extends StatelessWidget {
  final List<MapEntry<String, int>> items;
  final Color color;
  const BarList({super.key, required this.items, this.color = C.purple});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada data', style: TextStyle(color: C.muted)));
    final mx = items.map((e) => e.value).fold<int>(1, (a, b) => b > a ? b : a);
    return Column(
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 110, child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.ink))),
                  Expanded(
                    child: LayoutBuilder(builder: (c, box) {
                      final wd = box.maxWidth * (e.value / mx);
                      return Stack(children: [
                        Container(height: 14, decoration: BoxDecoration(color: color.op(.10), borderRadius: BorderRadius.circular(8))),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 14,
                          width: wd < 8 ? 8 : wd,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.op(.6)]), borderRadius: BorderRadius.circular(8)),
                        ),
                      ]);
                    }),
                  ),
                  SizedBox(width: 34, child: Text('${e.value}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
                ]),
              ))
          .toList(),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const StatTile(this.label, this.value, this.icon, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.op(.15), blurRadius: 14, offset: const Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.op(.14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.ink)),
          Text(label, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

Future<bool> confirm(BuildContext c, String title, String msg, {String ok = 'Ya'}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
      ],
    ),
  );
  return r ?? false;
}
