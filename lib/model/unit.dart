import 'dart:convert';

Units unitsFromJson(String str) => Units.fromJson(json.decode(str));

String unitsToJson(Units data) => json.encode(data.toJson());

class Units {
  Units({
    required this.kdUnit,
    required this.nmUnit,
    required this.latitude,
    required this.longitude,
    this.radiusAbsen = 25,
  });

  String kdUnit;
  String nmUnit;
  double latitude;  // UBAH: String -> double
  double longitude; // UBAH: String -> double
  // Radius absen unit, meter. Diatur lewat SQL, bukan build APK.
  double radiusAbsen;

  factory Units.fromJson(Map<String, dynamic> json) => Units(
    kdUnit: json["kd_unit"]?.toString() ?? '',
    nmUnit: json["nm_unit"]?.toString() ?? '',
    latitude: json["latitude"] != null
        ? double.tryParse(json["latitude"].toString()) ?? 0.0
        : 0.0,  // Konversi ke double
    longitude: json["longitude"] != null
        ? double.tryParse(json["longitude"].toString()) ?? 0.0
        : 0.0, // Konversi ke double
    radiusAbsen: json["radius_absen"] != null
        ? double.tryParse(json["radius_absen"].toString()) ?? 25
        : 25,
  );

  Map<String, dynamic> toJson() => {
    "kd_unit": kdUnit,
    "nm_unit": nmUnit,
    "latitude": latitude.toString(), // Konversi ke String untuk JSON
    "longitude": longitude.toString(),
    "radius_absen": radiusAbsen,
  };

  @override
  String toString() => nmUnit;
}