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
  final List<Color> grad;
  final WidgetBuilder builder;
  const Tool(this.title, this.subtitle, this.icon, this.grad, this.builder);
}

/// HANYA tool yang benar-benar berfungsi yang muncul di sini.
final List<Tool> kTools = [
  Tool('Gambar → PDF', 'Gabung foto jadi 1 PDF', Icons.picture_as_pdf,
      [Color(0xFFFF6B6B), Color(0xFFF0604C)], (_) => const ImageToPdfScreen()),
  Tool('PDF → Gambar', 'Setiap halaman jadi PNG', Icons.image_outlined,
      [Color(0xFF3B6EF5), Color(0xFF5B8DEF)], (_) => const PdfToImageScreen()),
  Tool('Gabung PDF', 'Beberapa PDF jadi satu', Icons.call_merge,
      [Color(0xFF12A45A), Color(0xFF27C06B)], (_) => const MergePdfScreen()),
  Tool('Pisah PDF', 'Ekstrak / pecah halaman', Icons.call_split,
      [Color(0xFFF7A23B), Color(0xFFE9912B)], (_) => const SplitPdfScreen()),
  Tool('Kompres PDF', 'Perkecil ukuran file', Icons.compress,
      [Color(0xFF6D5BF0), Color(0xFF8B6CF0)], (_) => const CompressPdfScreen()),
  Tool('Kompres Foto', 'Perkecil ukuran gambar', Icons.photo_size_select_large,
      [Color(0xFFEC4899), Color(0xFFF472B6)], (_) => const CompressImageScreen()),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _quotaTick = 0;
  void _refreshQuota() => setState(() => _quotaTick++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BannerAdBox(),
      body: PremiumBackground(
        child: SafeArea(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _Hero(key: ValueKey(_quotaTick), onChanged: _refreshQuota),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 26, 24, 16),
                child: Text('Semua alat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ToolCard(tool: kTools[i], onReturn: _refreshQuota),
                  childCount: kTools.length,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Hero header gradient: ikon + judul + subjudul + pil kuota.
class _Hero extends StatelessWidget {
  final VoidCallback onChanged;
  const _Hero({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: kHeroGradient,
        boxShadow: const [BoxShadow(color: Color(0x593B52C8), blurRadius: 34, offset: Offset(0, 18))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.4),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: const [
            Text('PDF Toolkit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5)),
            SizedBox(height: 2),
            Text('Cepat · Privat · Gratis', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14)),
          ]),
        ]),
        const SizedBox(height: 16),
        Text(
          'Konversi & olah PDF dan gambar — semua diproses langsung di HP-mu, tanpa upload.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 18),
        _QuotaPill(onChanged: onChanged),
      ]),
    );
  }
}

class _QuotaPill extends StatelessWidget {
  final VoidCallback onChanged;
  const _QuotaPill({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([Quota.isUnlimitedToday(), Quota.remaining()]),
      builder: (context, snap) {
        final unlimited = snap.hasData ? snap.data![0] as bool : false;
        final remaining = snap.hasData ? snap.data![1] as int : Quota.freeDailyLimit;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.4),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
              child: Icon(unlimited ? Icons.all_inclusive : Icons.bolt,
                  color: unlimited ? Colors.white : const Color(0xFFFFE08A), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                unlimited ? 'Akses tanpa batas aktif' : '$remaining konversi gratis hari ini',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
            if (!unlimited)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final ok = await unlockUnlimitedWithAd(context);
                  if (ok) onChanged();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Buka tanpa batas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    SizedBox(width: 6),
                    Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _ToolCard extends StatefulWidget {
  final Tool tool;
  final VoidCallback onReturn;
  const _ToolCard({required this.tool, required this.onReturn});
  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  double _scale = 1;
  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: tool.builder));
        widget.onReturn();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: cardDeco(),
          padding: const EdgeInsets.fromLTRB(22, 24, 18, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tool.grad),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: tool.grad.last.withValues(alpha: 0.40), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Icon(tool.icon, color: Colors.white, size: 32),
            ),
            const Spacer(),
            Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17.5, letterSpacing: -0.3)),
            const SizedBox(height: 5),
            Text(tool.subtitle, style: const TextStyle(color: C.muted, fontSize: 12.5, height: 1.25)),
          ]),
        ),
      ),
    );
  }
}
