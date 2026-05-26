import '../services/api_service.dart';
import '../config/app_config.dart';
import 'package:deep_pick/deep_pick.dart';

class KaryawanService {
  // Get karyawan data by device ID
  static Future<Map<String, dynamic>?> getKaryawanByDevice(String deviceId) async {
    final response = await ApiService.get(AppConfig.karyawanByDevice(deviceId));

    if (response != null && response['data'] != null && response['data'].length > 0) {
      final data = response['data'][0];
      return {
        'kar_nik': pick(data, 'kar_nik').asStringOrNull(),
        'kar_kd_unit': pick(data, 'kar_kd_unit').asStringOrNull(),
        'kar_nama': pick(data, 'kar_nama').asStringOrNull(),
        'kar_kd_jabat': pick(data, 'kar_kd_jabat').asStringOrNull(),
      };
    }
    return null;
  }

  // Get unit data by unit ID
  static Future<Map<String, dynamic>?> getUnitById(String unitId) async {
    final response = await ApiService.get(AppConfig.unitById(unitId));

    if (response != null && response['data'] != null && response['data'].length > 0) {
      final data = response['data'][0];
      return {
        'latitude': pick(data, 'latitude').asDoubleOrNull(),
        'longitude': pick(data, 'longitude').asDoubleOrNull(),
        'nm_unit': pick(data, 'nm_unit').asStringOrNull(),
      };
    }
    return null;
  }
}