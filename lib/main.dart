import 'package:flutter/material.dart';
import 'theme.dart';
import 'ads.dart';
import 'common.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BannerAdBox(),
      body: SafeArea(
        child: CustomScrollView(slivers: [
          const SliverToBoxAdapter(child: _Header()),
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
                (context, i) => _ToolCard(tool: kTools[i]),
                childCount: kTools.length,
              ),
            ),
          ),
        ]),
      ),
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
  const _ToolCard({required this.tool});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: tool.builder)),
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
