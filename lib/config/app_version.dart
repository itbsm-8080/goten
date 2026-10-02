// Versi aplikasi, diisi lewat --dart-define saat build release.
//
// Flutter tidak bisa membaca pubspec.yaml saat runtime, jadi nilainya datang dari
// flag build. Kalau kosong (mis. jalan dari IDE tanpa flag) pemeriksa update
// dilewati sepenuhnya - supaya tidak terkunci saat pengembangan lokal.
const appVersionCode = String.fromEnvironment('APP_VERSION_CODE', defaultValue: '');
const appVersionName = String.fromEnvironment('APP_VERSION_NAME', defaultValue: '');

/// Versi yang tampil di UI. Kosong kalau belum diisi --dart-define.
String get appVersiTampil => appVersionName.isEmpty ? '-' : appVersionName;

/// Hanya build yang punya --dart-define yang boleh mengecek update.
bool get appVersiDiketahui => appVersionCode.isNotEmpty;