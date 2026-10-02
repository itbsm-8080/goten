import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
// getExternalStorageDirectory(): di Android ini memetakan ke
// Context.getExternalFilesDir(), folder khusus app di penyimpanan eksternal.
// APK hasil unduhan harus ada di sini supaya Android bisa membacanya saat memasang
// - lihat android/app/src/main/res/xml/provider_paths.xml.
import 'package:path_provider/path_provider.dart' as path_provider;

import '../config/app_config.dart';
import '../config/app_version.dart';

/// Satu rilis yang tersedia di server.
class InfoUpdate {
  InfoUpdate({
    required this.versionCode,
    required this.versionName,
    required this.url,
    required this.md5,
    required this.ukuran,
    required this.wajib,
    required this.catatan,
  });

  final int versionCode;
  final String versionName;
  final String url;
  final String md5;
  final int ukuran;

  /// true = app tidak bisa dipakai sampai versi ini terpasang.
  final bool wajib;
  final String catatan;

  static InfoUpdate? dariJson(Map<String, dynamic> j) {
    final code = int.tryParse('${j['version_code'] ?? ''}');
    final url = '${j['url'] ?? ''}';
    if (code == null || url.isEmpty) return null;
    return InfoUpdate(
      versionCode: code,
      versionName: '${j['version_name'] ?? ''}',
      url: url,
      md5: '${j['md5'] ?? ''}'.toLowerCase(),
      ukuran: int.tryParse('${j['ukuran'] ?? ''}') ?? 0,
      wajib: j['wajib'] == true,
      catatan: '${j['catatan'] ?? ''}',
    );
  }

  String get ukuranTampil =>
      ukuran <= 0 ? '' : '${(ukuran / 1048576).toStringAsFixed(1)} MB';
}

/// Gagal saat mengunduh atau memverifikasi. Pesannya aman ditampilkan ke user.
class GagalUpdate implements Exception {
  GagalUpdate(this.pesan);
  final String pesan;

  @override
  String toString() => pesan;
}

/// Kemajuan unduhan yang sedang berjalan, supaya UI bisa menampilkan progress bar.
class DownloadUpdate {
  const DownloadUpdate(this.diterima, this.total);
  final int diterima;
  final int total;
}

class UpdateService {
  UpdateService._();

  static const _timeoutCek = Duration(seconds: 5);

  /// Diisi selama unduhan berjalan. Null ketika tidak ada unduhan aktif.
  static Stream<DownloadUpdate>? lajuUnduhan;

  /// Rilis yang lebih baru dari versi terpasang, atau null.
  ///
  /// Null juga dikembalikan kalau server tidak bisa dihubungi. Itu disengaja:
  /// kalau server mati dan app dikunci, seluruh staff tidak bisa absen.
  static Future<InfoUpdate?> cekUpdate() async {
    if (!appVersiDiketahui) return null;
    try {
      final r = await http
          .get(Uri.parse(AppConfig.updateManifestUrl))
          .timeout(_timeoutCek);
      if (r.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(r.bodyBytes));
      if (decoded is! Map) return null;
      final info = InfoUpdate.dariJson(Map<String, dynamic>.from(decoded));
      if (info == null) return null;
      if (info.versionCode <= int.parse(appVersionCode)) return null;
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Unduh APK, verifikasi md5, lalu serahkan ke Android untuk dipasang.
  ///
  /// Melempar [GagalUpdate] kalau jaringan putus atau md5 tidak cocok.
  static Future<void> unduhDanPasang(InfoUpdate info) async {
    final dir = await path_provider.getExternalStorageDirectory();
    if (dir == null) throw GagalUpdate('Tidak bisa menyiapkan folder penyimpanan');

    final target = File('${dir.path}/goten-release-${info.versionCode}.apk');

    // Percobaan sebelumnya mungkin sudah selesai mengunduh lalu install-nya
    // dibatalkan user. Pakai ulang supaya tidak mengunduh ulang 30 MB.
    var perluUnduh = true;
    if (await target.exists()) {
      if (info.md5.isEmpty || await _md5File(target) == info.md5) {
        perluUnduh = false;
      } else {
        await _hapus(target);
      }
    }

    if (perluUnduh) {
      final respons = await http.Client().send(http.Request('GET', Uri.parse(info.url)));
      if (respons.statusCode != 200) {
        throw GagalUpdate('Server menolak unduhan (${respons.statusCode})');
      }

      final laju = StreamController<DownloadUpdate>.broadcast();
      UpdateService.lajuUnduhan = laju.stream;

      final sink = target.openWrite();
      try {
        final total = respons.contentLength ?? info.ukuran;
        var diterima = 0;
        await for (final chunk in respons.stream) {
          diterima += chunk.length;
          sink.add(chunk);
          laju.add(DownloadUpdate(diterima, total));
        }
        await sink.flush();
        await sink.close();
      } catch (e) {
        await sink.close();
        // File setengah jadi tidak boleh ikut terinstall.
        await _hapus(target);
        throw GagalUpdate('Gagal mengunduh. Periksa koneksi internet');
      } finally {
        await laju.close();
        UpdateService.lajuUnduhan = null;
      }

      if (info.md5.isNotEmpty && await _md5File(target) != info.md5) {
        await _hapus(target);
        throw GagalUpdate('File tidak lengkap. Silakan coba lagi');
      }
    }

    final hasil = await OpenFilex.open(target.path);
    if (hasil.type != ResultType.done) {
      throw GagalUpdate(
        hasil.message.isEmpty
            ? 'Android tidak membuka file. Izinkan aplikasi ini '
                'memasang aplikasi lain di pengaturan sistem.'
            : hasil.message,
      );
    }
  }

  static Future<void> _hapus(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {
      // File terkunci tidak apa-apa, yang penting tidak ikut terinstall.
    }
  }

  static Future<String> _md5File(File f) async =>
      (await md5.bind(f.openRead()).first).toString();
}