import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../theme.dart';
import '../common.dart';

/// Ubah tiap halaman PDF menjadi gambar PNG.
class PdfToImageScreen extends StatefulWidget {
  const PdfToImageScreen({super.key});
  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<PdfToImageScreen> {
  String? _pdfPath;
  String? _pdfName;
  double _dpi = 150;

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (res != null && res.files.single.path != null) {
      setState(() {
        _pdfPath = res.files.single.path;
        _pdfName = res.files.single.name;
      });
    }
  }

  Future<void> _convert() async {
    final path = _pdfPath;
    if (path == null) {
      snack(context, 'Pilih file PDF dulu', error: true);
      return;
    }
    final paths = await runBusy<List<String>>(context, 'Mengubah halaman jadi gambar…', () async {
      final bytes = await File(path).readAsBytes();
      final dir = await outputDir();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final base = (_pdfName ?? 'pdf').replaceAll('.pdf', '');
      final out = <String>[];
      int page = 1;
      await for (final raster in Printing.raster(bytes, dpi: _dpi)) {
        final png = await raster.toPng();
        final f = File('${dir.path}/${base}_hal${page.toString().padLeft(2, '0')}_$stamp.png');
        await f.writeAsBytes(png, flush: true);
        out.add(f.path);
        page++;
      }
      return out;
    });
    if (paths != null && paths.isNotEmpty && mounted) {
      await goToResult(context,
          title: 'Berhasil dikonversi',
          subtitle: '${paths.length} halaman → gambar PNG',
          paths: paths);
    } else if (paths != null && paths.isEmpty && mounted) {
      snack(context, 'PDF tidak punya halaman yang bisa dibaca', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF → Gambar')),
      bottomNavigationBar: const BannerAdBox(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickPdf,
              child: Container(
                decoration: cardDeco(border: _pdfPath == null ? null : C.primary.withValues(alpha: 0.4)),
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  const Icon(Icons.picture_as_pdf, color: C.danger, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _pdfName ?? 'Ketuk untuk pilih file PDF',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _pdfName == null ? C.muted : C.ink),
                    ),
                  ),
                  const Icon(Icons.folder_open, color: C.muted),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Kualitas (DPI)', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${_dpi.round()}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.primary)),
            ]),
            Slider(
              value: _dpi,
              min: 72,
              max: 300,
              divisions: 19,
              activeColor: C.primary,
              label: '${_dpi.round()} DPI',
              onChanged: (v) => setState(() => _dpi = v),
            ),
            const Text('Makin tinggi DPI = makin tajam tapi file lebih besar.',
                style: TextStyle(color: C.muted, fontSize: 12)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _pdfPath == null ? null : _convert,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Konversi ke Gambar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: C.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: C.line,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ]),
        ),
      ),
    );
  }
}
