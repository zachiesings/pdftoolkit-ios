import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../theme.dart';
import '../common.dart';

/// Gabungkan beberapa file PDF menjadi satu (sesuai urutan daftar).
class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});
  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<PlatformFile> _files = [];

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (res != null) {
      setState(() => _files.addAll(res.files.where((f) => f.path != null)));
    }
  }

  Future<void> _merge() async {
    if (_files.length < 2) {
      snack(context, 'Pilih minimal 2 PDF', error: true);
      return;
    }
    final result = await runBusy<File>(context, 'Menggabungkan PDF…', () async {
      final out = PdfDocument();
      for (final f in _files) {
        final bytes = await File(f.path!).readAsBytes();
        final src = PdfDocument(inputBytes: bytes);
        out.importPageRange(src, 0, src.pages.count - 1);
        src.dispose();
      }
      final data = await out.save();
      out.dispose();
      final ts = DateTime.now().millisecondsSinceEpoch;
      return saveBytes('Gabungan_$ts.pdf', data);
    });
    if (result != null && mounted) {
      await goToResult(context,
          title: 'PDF tergabung',
          subtitle: '${_files.length} file digabung jadi 1 PDF',
          paths: [result.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gabung PDF')),
      bottomNavigationBar: const BannerAdBox(),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: _files.isEmpty
                ? const _Empty(icon: Icons.merge_type, msg: 'Belum ada PDF', sub: 'Pilih 2 file PDF atau lebih untuk digabung')
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _files.length,
                    onReorder: (a, b) => setState(() {
                      if (b > a) b -= 1;
                      final it = _files.removeAt(a);
                      _files.insert(b, it);
                    }),
                    itemBuilder: (_, i) {
                      final f = _files[i];
                      return Container(
                        key: ValueKey('${f.path}_$i'),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: cardDeco(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          CircleAvatar(radius: 13, backgroundColor: C.primary, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 12),
                          Expanded(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(onPressed: () => setState(() => _files.removeAt(i)), icon: const Icon(Icons.close, size: 18, color: C.muted)),
                          const Icon(Icons.drag_handle, color: C.muted),
                        ]),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.add),
                  label: Text(_files.isEmpty ? 'Pilih PDF' : 'Tambah'),
                  style: OutlinedButton.styleFrom(foregroundColor: C.primary, side: const BorderSide(color: C.primary), padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _files.length < 2 ? null : _merge,
                  icon: const Icon(Icons.merge_type),
                  label: const Text('Gabung'),
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

class _Empty extends StatelessWidget {
  final IconData icon;
  final String msg, sub;
  const _Empty({required this.icon, required this.msg, required this.sub});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: C.muted),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: C.muted, fontSize: 13))),
        ]),
      );
}
