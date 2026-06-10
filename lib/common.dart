import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme.dart';
import 'ads.dart';
import 'limits.dart';

/// Folder output di area privat aplikasi (tidak butuh izin storage).
Future<Directory> outputDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/PDFToolkit');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// Simpan bytes ke folder output dengan nama unik.
Future<File> saveBytes(String fileName, List<int> bytes) async {
  final dir = await outputDir();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<void> openFile(String path) => OpenFilex.open(path).then((_) {});

Future<void> shareFiles(List<String> paths, {String? text}) =>
    Share.shareXFiles(paths.map((p) => XFile(p)).toList(), text: text);

void snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? C.danger : C.ink,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Jalankan tugas berat sambil menampilkan overlay loading. Mengembalikan hasil
/// (atau null bila gagal — pesan error otomatis ditampilkan).
///
/// Sebelum menjalankan tugas, kuota harian diperiksa lewat [ensureCanConvert]:
/// bila kuota gratis habis pengguna ditawari menonton iklan berhadiah. Bila
/// pengguna menolak / belum membuka akses, fungsi mengembalikan null tanpa
/// menjalankan tugas. Sesudah tugas sukses, 1 kuota dipakai ([Quota.consume]).
Future<T?> runBusy<T>(BuildContext context, String label, Future<T> Function() task) async {
  if (!await ensureCanConvert(context)) return null;
  if (!context.mounted) return null;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BusyDialog(label: label),
  );
  try {
    final res = await task();
    await Quota.consume();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    return res;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      snack(context, 'Gagal: $e', error: true);
    }
    return null;
  }
}

class _BusyDialog extends StatelessWidget {
  final String label;
  const _BusyDialog({required this.label});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: C.primary)),
          const SizedBox(width: 18),
          Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}

/// Putar iklan berhadiah → bila ditonton sampai selesai, buka akses tanpa batas
/// untuk sisa hari ini. Mengembalikan true bila berhasil dibuka.
Future<bool> unlockUnlimitedWithAd(BuildContext context) async {
  if (!Ads.rewardedReady) {
    snack(context, 'Iklan belum siap, coba lagi beberapa detik.', error: true);
    return false;
  }
  final earned = await Ads.showRewarded();
  if (earned) {
    await Quota.unlockToday();
    if (context.mounted) snack(context, 'Akses tanpa batas terbuka sampai besok 🎉');
    return true;
  }
  if (context.mounted) {
    snack(context, 'Iklan belum selesai ditonton. Akses belum terbuka.', error: true);
  }
  return false;
}

/// Pastikan pengguna boleh melakukan konversi. Bila kuota gratis habis,
/// tawarkan menonton iklan berhadiah untuk membuka akses tanpa batas hari ini.
/// Mengembalikan true bila boleh lanjut.
Future<bool> ensureCanConvert(BuildContext context) async {
  if (await Quota.canConvert()) return true;
  if (!context.mounted) return false;
  final watch = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kuota gratis hari ini habis'),
      content: const Text(
        'Kamu sudah memakai jatah konversi gratis hari ini.\n\n'
        'Tonton 1 video singkat untuk membuka akses TANPA BATAS sampai besok.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Nanti'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.play_circle_fill, size: 20),
          label: const Text('Tonton iklan'),
          style: ElevatedButton.styleFrom(
              backgroundColor: C.primary, foregroundColor: Colors.white),
        ),
      ],
    ),
  );
  if (watch != true || !context.mounted) return false;
  return unlockUnlimitedWithAd(context);
}

/// Layar hasil standar: ringkasan + tombol Buka / Bagikan.
class ResultScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> paths; // file hasil
  const ResultScreen({super.key, required this.title, required this.subtitle, required this.paths});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selesai')),
      body: PremiumBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: cardDeco(),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF12A45A), Color(0xFF27C06B)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x5512A45A), blurRadius: 16, offset: Offset(0, 8))],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(color: C.muted, fontSize: 13)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              Text('${paths.length} file', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: paths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final name = paths[i].split('/').last;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => openFile(paths[i]),
                      child: Container(
                        decoration: cardDeco(),
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: C.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.insert_drive_file_rounded, color: C.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                          const Icon(Icons.open_in_new_rounded, size: 18, color: C.muted),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openFile(paths.first),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Buka'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: GradientButton(icon: Icons.ios_share, label: 'Bagikan', onPressed: () => shareFiles(paths))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Buka layar hasil + tampilkan interstitial (momen natural).
Future<void> goToResult(BuildContext context, {required String title, required String subtitle, required List<String> paths}) async {
  Ads.maybeShowInterstitial();
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ResultScreen(title: title, subtitle: subtitle, paths: paths)),
  );
}

/// Banner iklan adaptif untuk ditaruh di bawah layar.
class BannerAdBox extends StatefulWidget {
  const BannerAdBox({super.key});
  @override
  State<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends State<BannerAdBox> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: Ads.bannerUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox(height: 0);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _ad!.size.height.toDouble(),
        width: double.infinity,
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
