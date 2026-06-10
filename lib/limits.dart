import 'package:shared_preferences/shared_preferences.dart';

/// Batas pemakaian harian (model freemium).
///
/// Gratis: [freeDailyLimit] konversi per hari. Setelah habis, pengguna dapat
/// menonton 1 iklan berhadiah (rewarded) untuk membuka akses **tanpa batas
/// selama sisa hari ini**. (Pembelian dalam aplikasi / IAP untuk menghapus
/// batas secara permanen menyusul — lihat [isUnlimitedToday]/[unlockToday].)
class Quota {
  /// Jumlah konversi gratis per hari sebelum perlu menonton iklan.
  static const int freeDailyLimit = 3;

  static const _kCountDate = 'quota_count_date'; // tanggal hitungan berlaku
  static const _kCount = 'quota_count'; // jumlah konversi hari ini
  static const _kUnlockedDate = 'quota_unlocked_date'; // tanggal "unlimited" aktif

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Apakah hari ini sudah dibuka tanpa batas (mis. sesudah menonton iklan)?
  static Future<bool> isUnlimitedToday() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kUnlockedDate) == _today();
  }

  /// Sisa kuota gratis hari ini. Mengembalikan -1 bila sedang tanpa batas.
  static Future<int> remaining() async {
    if (await isUnlimitedToday()) return -1;
    final p = await SharedPreferences.getInstance();
    final used = (p.getString(_kCountDate) == _today()) ? (p.getInt(_kCount) ?? 0) : 0;
    final left = freeDailyLimit - used;
    return left < 0 ? 0 : left;
  }

  /// Boleh melakukan konversi sekarang tanpa menonton iklan?
  static Future<bool> canConvert() async {
    if (await isUnlimitedToday()) return true;
    return (await remaining()) > 0;
  }

  /// Catat 1 pemakaian (dipanggil sesudah konversi sukses). Tidak menambah
  /// hitungan bila sedang dalam mode tanpa batas.
  static Future<void> consume() async {
    if (await isUnlimitedToday()) return;
    final p = await SharedPreferences.getInstance();
    final today = _today();
    final used = (p.getString(_kCountDate) == today) ? (p.getInt(_kCount) ?? 0) : 0;
    await p.setString(_kCountDate, today);
    await p.setInt(_kCount, used + 1);
  }

  /// Buka akses tanpa batas untuk sisa hari ini (dipanggil sesudah hadiah iklan).
  static Future<void> unlockToday() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUnlockedDate, _today());
  }
}
