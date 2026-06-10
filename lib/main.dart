import 'package:flutter/material.dart';
import 'theme.dart';
import 'ads.dart';
import 'common.dart';
import 'limits.dart';
import 'tools/image_to_pdf.dart';
import 'tools/pdf_to_image.dart';
import 'tools/merge_pdf.dart';
import 'tools/split_pdf.dart';
import 'tools/compress_pdf.dart';
import 'tools/compress_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Ads.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Toolkit',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}

/// Satu alat di beranda.
class Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const Tool(this.title, this.subtitle, this.icon, this.color, this.builder);
}

/// HANYA tool yang benar-benar berfungsi yang muncul di sini.
/// (Tidak ada placeholder "segera hadir" — pelajaran dari proyek sebelumnya.)
final List<Tool> kTools = [
  Tool('Gambar → PDF', 'Gabung foto jadi 1 PDF', Icons.picture_as_pdf, C.danger,
      (_) => const ImageToPdfScreen()),
  Tool('PDF → Gambar', 'Setiap halaman jadi PNG', Icons.image_outlined, C.primary,
      (_) => const PdfToImageScreen()),
  Tool('Gabung PDF', 'Beberapa PDF jadi satu', Icons.merge_type, C.ok,
      (_) => const MergePdfScreen()),
  Tool('Pisah PDF', 'Ekstrak / pecah halaman', Icons.call_split, C.gold,
      (_) => const SplitPdfScreen()),
  Tool('Kompres PDF', 'Perkecil ukuran file', Icons.compress, C.primary2,
      (_) => const CompressPdfScreen()),
  Tool('Kompres Foto', 'Perkecil ukuran gambar', Icons.photo_size_select_large, C.danger,
      (_) => const CompressImageScreen()),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dipakai untuk memaksa _QuotaBar membaca ulang sisa kuota.
  int _quotaTick = 0;
  void _refreshQuota() => setState(() => _quotaTick++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BannerAdBox(),
      body: SafeArea(
        child: CustomScrollView(slivers: [
          const SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(
            child: _QuotaBar(key: ValueKey(_quotaTick), onChanged: _refreshQuota),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ToolCard(tool: kTools[i], onReturn: _refreshQuota),
                childCount: kTools.length,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Bar status kuota harian + tombol "buka tanpa batas" (nonton iklan berhadiah).
class _QuotaBar extends StatelessWidget {
  final VoidCallback onChanged;
  const _QuotaBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([Quota.isUnlimitedToday(), Quota.remaining()]),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 0);
        final unlimited = snap.data![0] as bool;
        final remaining = snap.data![1] as int;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: cardDeco(
              border: unlimited ? C.ok.withValues(alpha: 0.4) : null),
          child: Row(children: [
            Icon(unlimited ? Icons.all_inclusive : Icons.bolt,
                color: unlimited ? C.ok : C.gold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                unlimited
                    ? 'Akses tanpa batas aktif hari ini'
                    : 'Sisa $remaining konversi gratis hari ini',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            if (!unlimited)
              TextButton.icon(
                onPressed: () async {
                  final ok = await unlockUnlimitedWithAd(context);
                  if (ok) onChanged();
                },
                icon: const Icon(Icons.play_circle_fill, size: 18),
                label: const Text('Buka tanpa batas'),
                style: TextButton.styleFrom(foregroundColor: C.primary),
              ),
          ]),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [C.primary, C.primary2]),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.auto_awesome_mosaic, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text('PDF Toolkit', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        ]),
        const SizedBox(height: 10),
        const Text('Konversi & olah PDF dan gambar — semua diproses langsung di HP-mu, tanpa upload.',
            style: TextStyle(color: C.muted, fontSize: 13, height: 1.35)),
      ]),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback onReturn;
  const _ToolCard({required this.tool, required this.onReturn});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: tool.builder));
        onReturn();
      },
      child: Container(
        decoration: cardDeco(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: tool.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(tool.icon, color: tool.color, size: 26),
          ),
          const Spacer(),
          Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 3),
          Text(tool.subtitle, style: const TextStyle(color: C.muted, fontSize: 12, height: 1.25)),
        ]),
      ),
    );
  }
}
