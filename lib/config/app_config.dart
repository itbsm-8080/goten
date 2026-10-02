import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://a9fc51ba29ac.ngrok-free.app';
  static int get apiTimeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
  static String get appName => dotenv.env['APP_NAME'] ?? 'GOTEN';

  // API Endpoints
  static String get unitEndpoint => '$baseUrl/unit';
  static String get registrasiEndpoint => '$baseUrl/karyawan/registrasi';
  static String get absensiHariIni => '$baseUrl/absensi/hari-ini';
  static String get absensiHistory => '$baseUrl/absensi/history';
  static String get absensiTambah => '$baseUrl/absensi/tambah';
  static String get absensiShift => '$baseUrl/absensi/shift';
  static String get jabatanEndpoint => '$baseUrl/jabatan';
  static String get rotiQUnitsEndpoint => "$baseUrl/unitrotiq";

  // Manifest versi aplikasi. Menunjuk ke file JSON yang menyebut APK terbaru,
  // supaya user tidak perlu mengunduh langsung dari halaman web.
  static String get updateManifestUrl =>
      dotenv.env['UPDATE_URL'] ?? 'http://103.103.22.7/cutikaryawan/apk/version.json';


  // Dynamic endpoints
  static String karyawanByDevice(String deviceId) => '$baseUrl/karyawan/device_id/$deviceId';
  static String karyawanByUnit(String unitId) => '$baseUrl/karyawan/unit/$unitId';
  static String unitById(String unitId) => '$baseUrl/unit/$unitId';
  static String jabatanByKode(String kode) => '$baseUrl/jabatan/$kode';

  static String get uploadIzinEndpoint => '$baseUrl/cutikaryawan/upload.php';

  // Upload & tampil foto (pakai server file seperti Delphi)
  static String get uploadFotoEndpoint => dotenv.env['UPLOAD_URL'] ?? 'http://103.103.22.7/cutikaryawan/upload.php';
  static String get buktiBaseUrl => dotenv.env['BUKTI_URL'] ?? 'http://103.103.22.7/cutikaryawan/bukti';
}
