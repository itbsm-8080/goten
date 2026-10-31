import '../config/app_config.dart';
import 'api_service.dart';

class IzinService {
  static Future<Map<String, dynamic>?> getListIzin({
    required String karNik,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/izin/list', {
      'kar_nik': karNik,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null && status != 'ALL') 'status': status,
    });
  }

  static Future<bool> tambahIzin({
    required String karNik,
    required String tanggal,
    required String alasan,
    required String keterangan,
    String? foto,
  }) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/izin/tambah', {
      'kar_nik': karNik,
      'tanggal': tanggal,
      'alasan': alasan,
      'keterangan': keterangan,
      if (foto != null) 'ij_foto': foto,
    });
    return response != null && response['success'] == true;
  }

  static Future<bool> editIzin({
    required String ijNomor,
    required String tanggal,
    required String alasan,
    required String keterangan,
    String? foto,
  }) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/izin/edit', {
      'ij_nomor': ijNomor,
      'tanggal': tanggal,
      'alasan': alasan,
      'keterangan': keterangan,
      if (foto != null) 'ij_foto': foto,
    });
    return response != null && response['success'] == true;
  }

  static Future<bool> hapusIzin(String ijNomor) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/izin/hapus', {
      'ij_nomor': ijNomor,
    });
    return response != null && response['success'] == true;
  }

  static Future<Map<String, dynamic>?> cekRoleApproval(String karNik) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/approval/cek-role', {
      'kar_nik': karNik,
    });
  }


  static Future<Map<String, dynamic>?> getApprovalList({
    required List<String> kdUnits,  // ubah jadi List
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/izin/approval-list', {
      'kd_units': kdUnits.join(','),  // kirim sebagai string comma-separated
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null && status != 'ALL') 'status': status,
    });
  }

  static Future<bool> prosesIzin(String ijNomor, String status, {String? karNik}) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/izin/proses', {
      'ij_nomor': ijNomor,
      'ij_status': status,
      if (karNik != null) 'kar_nik': karNik,
    });
    return response != null && response['success'] == true;
  }

  static Future<Map<String, dynamic>?> getSisaCuti(String karNik) async {
    print('🔍 getSisaCuti untuk: $karNik');
    final response = await ApiService.postFormData(
      '${AppConfig.baseUrl}/izin/sisa-cuti',
      {'kar_nik': karNik},
    );
    print('📦 Response sisa cuti: $response');
    return response;
  }

  static Future<Map<String, dynamic>?> cekRotiQMobile(String karNik) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/izin/cek-rotiq-mobile', {
      'kar_nik': karNik,
    });
  }

  static Future<Map<String, dynamic>?> getLaporanIzin({
    required String karNik,
    String? startDate,
    String? endDate,
  }) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/izin/laporan', {
      'kar_nik': karNik,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
  }
}