import '../config/app_config.dart';
import '../services/api_service.dart';
import '../model/unit.dart';

class UnitService {
  static Future<List<Units>> getRotiQUnits() async {
    try {
      final response = await ApiService.get(AppConfig.rotiQUnitsEndpoint);

      if (response != null && response['data'] != null) {
        List allUnits = response['data'];
        List<Units> unitsModels = [];

        allUnits.forEach((element) {
          unitsModels.add(Units(
            kdUnit: element['kd_unit']?.toString() ?? '',
            nmUnit: element['nm_unit']?.toString() ?? '',
            latitude: element['latitude'] != null
                ? double.tryParse(element['latitude'].toString()) ?? 0.0
                : 0.0,
            longitude: element['longitude'] != null
                ? double.tryParse(element['longitude'].toString()) ?? 0.0
                : 0.0,
          ));
        });

        return unitsModels;
      }
    } catch (e) {
      print('Error loading RotiQ units: $e');
    }
    return [];
  }
}