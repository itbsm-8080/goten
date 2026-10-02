import '../config/app_config.dart';
import 'api_service.dart';

class PodService {
  static Future<Map<String, dynamic>?> getListPOD({
    required String karNik,
    String? startDate,
    String? endDate,
  }) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/pod/list', {
      'kar_nik': karNik,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
  }

  static Future<Map<String, dynamic>?> getListBelum({
    required String karNik,
  }) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/pod/list-belum', {
      'kar_nik': karNik,
    });
  }

  static Future<Map<String, dynamic>?> cariDO({
    required String karNik,
    String? startDate,
    String? keyword,
  }) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/pod/cari-do', {
      'kar_nik': karNik,
      if (startDate != null) 'start_date': startDate,
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
    });
  }

  static Future<bool> tambahPOD({
    required String karNik,
    required String podDoNomor,
    required String podTanggal,
    required String podFoto,
    required String podCusKode,
  }) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/pod/tambah', {
      'kar_nik': karNik,
      'pod_do_nomor': podDoNomor,
      'pod_tanggal': podTanggal,
      'pod_foto': podFoto,
      'pod_cus_kode': podCusKode,
    });
    return response != null && response['success'] == true;
  }

  static Future<bool> editPOD({
    required String karNik,
    required String podNomor,
    required String podTanggal,
    String? podFoto,
  }) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/pod/edit', {
      'kar_nik': karNik,
      'pod_nomor': podNomor,
      'pod_tanggal': podTanggal,
      if (podFoto != null) 'pod_foto': podFoto,
    });
    return response != null && response['success'] == true;
  }

  static Future<bool> hapusPOD({
    required String karNik,
    required String podNomor,
  }) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/pod/hapus', {
      'kar_nik': karNik,
      'pod_nomor': podNomor,
    });
    return response != null && response['success'] == true;
  }
}
