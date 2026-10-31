import '../config/app_config.dart';
import 'api_service.dart';

class LemburService {
  static Future<Map<String, dynamic>?> getApprovalList({
    required List<String> kdUnits,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    return await ApiService.postFormData('${AppConfig.baseUrl}/lembur/approval-list', {
      'kd_units': kdUnits.join(','),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null && status != 'ALL') 'status': status,
    });
  }

  static Future<bool> prosesLembur(String lemNomor, String status, {String? karNik}) async {
    final response = await ApiService.postFormData('${AppConfig.baseUrl}/lembur/proses', {
      'lem_nomor': lemNomor,
      'lem_status': status,
      if (karNik != null) 'kar_nik': karNik,
    });
    return response != null && response['success'] == true;
  }
}
