import '../services/api_service.dart';
import '../config/app_config.dart';
import 'package:deep_pick/deep_pick.dart';

class JabatanService {
  // Get jabatan by kode
  static Future<String?> getJabatanByKode(String kode) async {
    final response = await ApiService.get(AppConfig.jabatanByKode(kode));

    if (response != null && response['data'] != null && response['data'].length > 0) {
      return pick(response['data'][0], 'nm_jabat').asStringOrNull();
    }
    return null;
  }
}