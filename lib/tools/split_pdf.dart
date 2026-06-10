import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../theme.dart';
import '../common.dart';

/// Pisah PDF: ekstrak rentang halaman, atau pecah jadi per-halaman.
class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});
  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _path;
  String? _name;
  int _count = 0;
  RangeValues _range = const RangeValues(1, 1);

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res == null || res.files.single.path == null) return;
    final path = res.files.single.path!;
    final bytes = await File(path).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final c = doc.pages.count;
    doc.dispose();
    setState(() {
      _path = path;
      _name = res.files.single.name;
      _count = c;
      _range = RangeValues(1, c.toDouble());
    });
  }

  String _baseName() => (_name ?? 'pdf').replaceAll('.pdf', '');

  Future<void> _extractRange() async {
    final path = _path;
    if (path == null) return;
    final start = _range.start.round();
    final end = _range.end.round();
    final result = await runBusy<File>(context, 'Mengekstrak halaman…', () async {
      final bytes = await File(path).readAsBytes();
      final src = PdfDocument(inputBytes: bytes);
      final out = PdfDocument();
      out.importPageRange(src, start - 1, end - 1);
      final data = await out.save();
      src.dispose();
      out.dispose();
      final ts = DateTime.now().millisecondsSinceEpoch;
      return saveBytes('${_baseName()}_hal$start-${end}_$ts.pdf', data);
    });
    if (result != null && mounted) {
      await goToResult(context, title: 'Halaman diekstrak', subtitle: 'Halaman $start–$end → 1 PDF', paths: [result.path]);
    }
  }

  Future<void> _splitEach() async {
    final path = _path;
    if (path == null) return;
    final paths = await runBusy<List<String>>(context, 'Memecah tiap halaman…', () async {
      final bytes = await File(path).readAsBytes();
      final src = PdfDocument(inputBytes: bytes);
      final n = src.pages.count;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final out = <String>[];
      for (var i = 0; i < n; i++) {
        final one = PdfDocument();
        one.importPageRange(src, i, i);
        final data = await one.save();
        one.dispose();
        final f = await saveBytes('${_baseName()}_hal${(i + 1).toString().padLeft(2, '0')}_$ts.pdf', data);
        out.add(f.path);
      }
      src.dispose();
      return out;
    });
    if (paths != null && paths.isNotEmpty && mounted) {
      await goToResult(context, title: 'PDF dipecah', subtitle: '${paths.length} halaman → ${paths.length} file PDF', paths: paths);
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = _path != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Pisah PDF')),
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
                    child: Text(_name ?? 'Ketuk untuk pilih file PDF',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, color: has ? C.ink : C.muted)),
                  ),
                  const Icon(Icons.folder_open, color: C.muted),
                ]),
              ),
            ),
            if (has) ...[
              const SizedBox(height: 8),
              Text('$_count halaman', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Ambil halaman', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('${_range.start.round()} – ${_range.end.round()}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.primary)),
              ]),
              if (_count > 1)
                RangeSlider(
                  values: _range,
                  min: 1,
                  max: _count.toDouble(),
                  divisions: _count - 1,
                  activeColor: C.primary,
                  labels: RangeLabels('${_range.start.round()}', '${_range.end.round()}'),
                  onChanged: (v) => setState(() => _range = RangeValues(v.start.roundToDouble(), v.end.roundToDouble())),
                ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _extractRange,
                icon: const Icon(Icons.content_cut),
                label: Text('Ekstrak halaman ${_range.start.round()}–${_range.end.round()}'),
                style: ElevatedButton.styleFrom(backgroundColor: C.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _splitEach,
                icon: const Icon(Icons.call_split),
                label: const Text('Pisah jadi per-halaman'),
                style: OutlinedButton.styleFrom(foregroundColor: C.primary, side: const BorderSide(color: C.primary), padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ],
            const Spacer(),
          ]),
        ),
      ),
    );
  }
}
