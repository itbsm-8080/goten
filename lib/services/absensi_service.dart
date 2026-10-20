import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../model/history_absen.dart';

class AbsensiResult {
  final bool success;
  final String message;
  final String code;
  final int? shift;
  final String? tanggalKerja;
  final bool terlambat;
  // true kalau check-out ini menggantikan check-out sebelumnya (batas 3x / 18 jam).
  final bool perbaikan;

  const AbsensiResult({
    required this.success,
    required this.message,
    this.code = '',
    this.shift,
    this.tanggalKerja,
    this.terlambat = false,
    this.perbaikan = false,
  });
}

class AbsensiService {
  // Get absensi history
  static Future<List<HistoryAbsensi>> getHistoryAbsensi(String karNama) async {
    final response = await ApiService.postFormData(
        AppConfig.absensiHistory,
        {"kar_nama": karNama}
    );

    if (response != null && response['data'] != null) {
      List allDataAbsensi = response['data'];
      List<HistoryAbsensi> dataabsensiModels = [];

      allDataAbsensi.forEach((element) {
        dataabsensiModels.add(HistoryAbsensi(
            nama: element['Nama'],
            tanggal: element['Tanggal'],
            historyAbsensiIn: element['_IN'],
            out: element['_OUT'],
            status: element['Status']
        ));
      });

      return dataabsensiModels;
    }

    return [];
  }

  // Daftar shift hari ini + usulan shift dari server (default jam).
  static Future<Map<String, dynamic>?> getShifts(String karNik) async {
    return await ApiService.postFormData(AppConfig.absensiShift, {'kar_nik': karNik});
  }

  // Submit absensi. status 1 = check-in, 2 = check-out (tombol yang menentukan).
  // shift 0 = Day Shift. Server memaksa 0 hari Minggu dan memvalidasi transisinya.
  static Future<AbsensiResult> submitAbsensi({
    required String karNik,
    required String kdCabang,
    required String latitude,
    required String longitude,
    required int status,
    required int shift,
    // Cabang absen untuk akunting unit 18 yang lintas cabang BSM.
    String? kdUnit,
  }) async {
    final response = await ApiService.postRaw(
      AppConfig.absensiTambah,
      {
        "kar_nik": karNik,
        "kd_cabang": kdCabang,
        "latitude": latitude,
        "longitude": longitude,
        "status_absen": status.toString(),
        "shift": shift.toString(),
        if (kdUnit != null) "kd_unit": kdUnit,
      },
    );

    if (response == null) {
      return const AbsensiResult(success: false, message: 'Gagal terhubung ke server');
    }

    try {
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return AbsensiResult(
          success: true,
          message: body['message'] as String? ?? 'Berhasil',
          shift: (body['shift'] as num?)?.toInt(),
          tanggalKerja: body['tanggal_kerja'] as String?,
          terlambat: body['terlambat'] == true,
          perbaikan: body['perbaikan'] == true,
        );
      }
      return AbsensiResult(
        success: false,
        message: body['message'] as String? ?? 'Terjadi kesalahan',
        code: body['code'] as String? ?? 'error',
        shift: (body['shift'] as num?)?.toInt(),
      );
    } catch (_) {
      return AbsensiResult(success: false, message: 'Respons tidak valid dari server');
    }
  }

  // Sesi absensi per (tanggal_kerja, shift) untuk 7 hari terakhir, plus shift yang
  // masih punya check-in terbuka (open_shift) supaya client tidak perlu menebak.
  static Future<Map<String, dynamic>> getAbsensiHariIni(String karNama) async {
    final response = await ApiService.postFormData(
      AppConfig.absensiHariIni,
      {"kar_nama": karNama}
    );

    final sessions = <Map<String, dynamic>>[];
    if (response != null) {
      final rawData = response['data'];
      final data = rawData is List ? rawData : const [];
      for (final d in data) {
        if (d is Map) {
          sessions.add({
            'tanggal_kerja': d['Tanggal'],
            'shift': (d['shift'] as num?)?.toInt() ?? 0,
            'shift_name': d['shift_name'] ?? 'Day Shift',
            'masuk': d['_IN'],
            'keluar': d['_OUT'],
            'status': d['Status'],
          });
        }
      }
    }

    return {
      'sessions': sessions,
      'focus': response?['workDate'] ?? null,
      'current_hour': response?['current_hour'] ?? null,
      'today': response?['today'] ?? null,
      // Work date yang boleh tampil di kartu. Server yang menentukan, client
      // tidak ikut menghitung aturan 01:00/09:00.
      'sesi_tampil': (response?['sesi_tampil'] as List?)?.cast<String>() ?? const <String>[],
        'open_shift': (response?['open_shift'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const <int>[],
    };
  }

  // Add registration method for HomePage
  static Future<bool> doRegistrasi({
    required String kdUnit,
    required String karNama,
    required String deviceId,
  }) async {
    final response = await ApiService.postFormData(
        AppConfig.registrasiEndpoint,
        {
          "kd_unit": kdUnit,
          "kar_nm": karNama,
          "device_id": deviceId,
        }
    );

    return response != null;
  }
}