import '../services/api_service.dart';
import '../config/app_config.dart';
import '../model/history_absen.dart';
import 'package:deep_pick/deep_pick.dart';

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

  // Submit absensi
  static Future<bool> submitAbsensi({
    required String karNik,
    required String tanggal,
    required String kdCabang,
    required String latitude,
    required String longitude,
  }) async {
    final response = await ApiService.postFormData(
        AppConfig.absensiTambah,
        {
          "kar_nik": karNik,
          "tanggal": tanggal,
          "kd_cabang": kdCabang,
          "latitude": latitude,
          "longitude": longitude,
        }
    );

    return response != null;
  }

  // Get absensi hari ini
  static Future<Map<String, String?>> getAbsensiHariIni(String karNama) async {
    final response = await ApiService.postFormData(
        AppConfig.absensiHariIni,
        {"kar_nama": karNama}
    );

    if (response != null) {
      final masuk = pick(response, 'data', 0, '_IN').asStringOrNull();
      final keluar = pick(response, 'data', 0, '_OUT').asStringOrNull();

      return {
        'masuk': masuk,
        'keluar': keluar,
      };
    }

    return {
      'masuk': null,
      'keluar': null,
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

