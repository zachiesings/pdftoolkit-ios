import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../theme.dart';
import '../common.dart';
import '../util.dart';

/// Perkecil ukuran PDF dengan me-render ulang tiap halaman sebagai JPEG.
/// (Cocok untuk PDF hasil scan/foto. Teks jadi gambar — tidak bisa diseleksi.)
class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});
  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _Preset {
  final String label;
  final double dpi;
  final int quality;
  const _Preset(this.label, this.dpi, this.quality);
}

const _presets = [
  _Preset('Kecil', 100, 50),
  _Preset('Sedang', 130, 65),
  _Preset('Bagus', 160, 80),
];

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  String? _path;
  String? _name;
  int _oldSize = 0;
  int _preset = 1;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res == null || res.files.single.path == null) return;
    final path = res.files.single.path!;
    setState(() {
      _path = path;
      _name = res.files.single.name;
      _oldSize = File(path).lengthSync();
    });
  }

  Future<void> _compress() async {
    final path = _path;
    if (path == null) return;
    final p = _presets[_preset];
    final res = await runBusy<File>(context, 'Mengompres PDF…', () async {
      final bytes = await File(path).readAsBytes();
      final doc = pw.Document();
      await for (final raster in Printing.raster(bytes, dpi: p.dpi)) {
        final png = await raster.toPng();
        final decoded = img.decodeImage(png);
        final jpg = decoded != null ? img.encodeJpg(decoded, quality: p.quality) : png;
        final mem = pw.MemoryImage(jpg);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat(raster.width.toDouble(), raster.height.toDouble()),
          build: (_) => pw.FullPage(ignoreMargins: true, child: pw.Image(mem, fit: pw.BoxFit.contain)),
        ));
      }
      final out = await doc.save();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final base = (_name ?? 'pdf').replaceAll('.pdf', '');
      return saveBytes('${base}_kompres_$ts.pdf', out);
    });
    if (res != null && mounted) {
      final newSize = res.lengthSync();
      final pct = _oldSize > 0 ? (100 - newSize / _oldSize * 100).round() : 0;
      await goToResult(context,
          title: 'PDF dikompres',
          subtitle: '${humanSize(_oldSize)} → ${humanSize(newSize)}  (${pct >= 0 ? '-$pct' : '+${-pct}'}%)',
          paths: [res.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = _path != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Kompres PDF')),
      bottomNavigationBar: const BannerAdBox(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pick,
              child: Container(
                decoration: cardDeco(border: has ? C.primary.withValues(alpha: 0.4) : null),
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  const Icon(Icons.picture_as_pdf, color: C.danger, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_name ?? 'Ketuk untuk pilih file PDF', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: has ? C.ink : C.muted)),
                      if (has) Text(humanSize(_oldSize), style: const TextStyle(color: C.muted, fontSize: 12)),
                    ]),
                  ),
                  const Icon(Icons.folder_open, color: C.muted),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tingkat kualitas', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: List.generate(_presets.length, (i) {
              final sel = i == _preset;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _presets.length - 1 ? 10 : 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _preset = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? C.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? C.primary : C.line, width: 1.5),
                      ),
                      child: Text(_presets[i].label, style: TextStyle(fontWeight: FontWeight.w800, color: sel ? Colors.white : C.ink)),
                    ),
                  ),
                ),
              );
            })),
            const SizedBox(height: 10),
            const Text('Kualitas lebih rendah = ukuran lebih kecil. Cocok untuk PDF berisi foto/scan.',
                style: TextStyle(color: C.muted, fontSize: 12)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: has ? _compress : null,
              icon: const Icon(Icons.compress),
              label: const Text('Kompres PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: C.primary, foregroundColor: Colors.white, disabledBackgroundColor: C.line, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ]),
        ),
      ),
    );
  }
}
