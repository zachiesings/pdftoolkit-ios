import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../theme.dart';
import '../common.dart';

/// Gabungkan beberapa gambar menjadi satu file PDF (1 gambar = 1 halaman).
class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});
  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<XFile> _images = [];

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 100);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  Future<void> _convert() async {
    if (_images.isEmpty) {
      snack(context, 'Pilih gambar dulu', error: true);
      return;
    }
    final result = await runBusy<File>(context, 'Membuat PDF…', () async {
      final doc = pw.Document();
      for (final x in _images) {
        final bytes = await File(x.path).readAsBytes();
        final img = pw.MemoryImage(bytes);
        final w = (img.width ?? 1000).toDouble();
        final h = (img.height ?? 1000).toDouble();
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat(w, h),
          build: (_) => pw.FullPage(ignoreMargins: true, child: pw.Image(img, fit: pw.BoxFit.contain)),
        ));
      }
      final out = await doc.save();
      final ts = DateTime.now().millisecondsSinceEpoch;
      return saveBytes('Gambar_ke_PDF_$ts.pdf', out);
    });
    if (result != null && mounted) {
      await goToResult(context,
          title: 'PDF berhasil dibuat',
          subtitle: '${_images.length} gambar digabung jadi 1 PDF',
          paths: [result.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gambar → PDF')),
      bottomNavigationBar: const BannerAdBox(),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: _images.isEmpty
                ? _empty()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: _images.length,
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.file(File(_images[i].path), fit: BoxFit.cover),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: const CircleAvatar(
                                radius: 13,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 16, color: Colors.white)),
                          ),
                        ),
                      ]),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_images.isEmpty ? 'Pilih gambar' : 'Tambah'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: C.primary,
                      side: const BorderSide(color: C.primary),
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _images.isEmpty ? null : _convert,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Buat PDF'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: C.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: C.line,
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.image_outlined, size: 64, color: C.muted),
          SizedBox(height: 12),
          Text('Belum ada gambar', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Pilih beberapa foto untuk dijadikan satu PDF', style: TextStyle(color: C.muted, fontSize: 13)),
        ]),
      );
}
