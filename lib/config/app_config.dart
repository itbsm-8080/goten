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
  static String get jabatanEndpoint => '$baseUrl/jabatan';
  static String get rotiQUnitsEndpoint => "$baseUrl/unitrotiq";


  // Dynamic endpoints
  static String karyawanByDevice(String deviceId) => '$baseUrl/karyawan/device_id/$deviceId';
  static String karyawanByUnit(String unitId) => '$baseUrl/karyawan/unit/$unitId';
  static String unitById(String unitId) => '$baseUrl/unit/$unitId';
  static String jabatanByKode(String kode) => '$baseUrl/jabatan/$kode';
}
