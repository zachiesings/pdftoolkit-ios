import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../theme.dart';
import '../common.dart';
import '../util.dart';

/// Perkecil ukuran gambar: atur kualitas JPEG + batasi dimensi maksimum.
class CompressImageScreen extends StatefulWidget {
  const CompressImageScreen({super.key});
  @override
  State<CompressImageScreen> createState() => _CompressImageScreenState();
}

class _CompressImageScreenState extends State<CompressImageScreen> {
  final List<XFile> _images = [];
  double _quality = 70;
  int? _maxDim = 1920; // null = ukuran asli

  static const _dims = <String, int?>{
    'Asli': null,
    '2048 px': 2048,
    '1920 px': 1920,
    '1280 px': 1280,
    '1024 px': 1024,
  };

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 100);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  Future<void> _compress() async {
    if (_images.isEmpty) {
      snack(context, 'Pilih gambar dulu', error: true);
      return;
    }
    int oldTotal = 0, newTotal = 0;
    final paths = await runBusy<List<String>>(context, 'Mengompres gambar…', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final out = <String>[];
      for (var i = 0; i < _images.length; i++) {
        final bytes = await File(_images[i].path).readAsBytes();
        oldTotal += bytes.length;
        var image = img.decodeImage(bytes);
        if (image == null) continue;
        final mx = _maxDim;
        if (mx != null && (image.width > mx || image.height > mx)) {
          image = image.width >= image.height
              ? img.copyResize(image, width: mx)
              : img.copyResize(image, height: mx);
        }
        final jpg = img.encodeJpg(image, quality: _quality.round());
        newTotal += jpg.length;
        final f = await saveBytes('kompres_${ts}_${i + 1}.jpg', jpg);
        out.add(f.path);
      }
      return out;
    });
    if (paths != null && paths.isNotEmpty && mounted) {
      final pct = oldTotal > 0 ? (100 - newTotal / oldTotal * 100).round() : 0;
      await goToResult(context,
          title: 'Gambar dikompres',
          subtitle: '${humanSize(oldTotal)} → ${humanSize(newTotal)}  (${pct >= 0 ? '-$pct' : '+${-pct}'}%)',
          paths: paths);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kompres Foto')),
      bottomNavigationBar: const BannerAdBox(),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: _images.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.compress, size: 64, color: C.muted),
                      SizedBox(height: 12),
                      Text('Belum ada gambar', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Pilih foto untuk diperkecil ukurannya', style: TextStyle(color: C.muted, fontSize: 13)),
                    ]),
                  )
                : ListView(padding: const EdgeInsets.all(16), children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: _images.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.file(File(_images[i].path), fit: BoxFit.cover),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(i)),
                              child: const CircleAvatar(radius: 13, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Kualitas', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('${_quality.round()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: C.primary)),
                    ]),
                    Slider(value: _quality, min: 20, max: 95, divisions: 15, activeColor: C.primary, label: '${_quality.round()}%', onChanged: (v) => setState(() => _quality = v)),
                    const SizedBox(height: 8),
                    const Text('Ukuran maksimum (sisi terpanjang)', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: _dims.entries.map((e) {
                      final sel = _maxDim == e.value;
                      return ChoiceChip(
                        label: Text(e.key),
                        selected: sel,
                        selectedColor: C.primary,
                        labelStyle: TextStyle(color: sel ? Colors.white : C.ink, fontWeight: FontWeight.w700),
                        onSelected: (_) => setState(() => _maxDim = e.value),
                      );
                    }).toList()),
                  ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_images.isEmpty ? 'Pilih gambar' : 'Tambah'),
                  style: OutlinedButton.styleFrom(foregroundColor: C.primary, side: const BorderSide(color: C.primary), padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _images.isEmpty ? null : _compress,
                  icon: const Icon(Icons.compress),
                  label: const Text('Kompres'),
                  style: ElevatedButton.styleFrom(backgroundColor: C.primary, foregroundColor: Colors.white, disabledBackgroundColor: C.line, padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
