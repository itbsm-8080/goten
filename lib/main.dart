import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'dashboard_baru.dart';
import 'approval_izin_page.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/update_service.dart';
import 'utils/device_utils.dart';
import 'widgets/update_dialog.dart';
import 'package:deep_pick/deep_pick.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _deviceId;
  String? _isLoggedIn;
  String? _karNik;
  static final String oneSignalAppId = "e82ad139-8162-46bd-989f-82f42dfb474e";

  Future<void> initPlatformState() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);

    // Handle notification click
    OneSignal.Notifications.addClickListener((event) {
      print("Notifikasi dibuka: ${event.notification.jsonRepresentation()}");

      // Ambil data dari notifikasi
      final additionalData = event.notification.additionalData;

      // Navigasi ke halaman approval
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ApprovalIzinPage(karNik: _karNik),
          ),
        );
      }
    });

    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print("Notifikasi diterima (foreground): ${event.notification.jsonRepresentation()}");
      event.preventDefault(); // Cegah tampil otomatis
      event.notification.display(); // Tampilkan notifikasi
    });
  }

  Future<void> cekLogin() async {
    String? deviceId;

    try {
      deviceId = await DeviceUtils.getDeviceId();
      if (deviceId == null) {
        deviceId = 'Failed to get deviceId.';
      }
    } catch (e) {
      deviceId = 'Failed to get deviceId.';
      print('Error getting device ID: $e');
    }

    if (!mounted) return;

    final response = await ApiService.get(AppConfig.karyawanByDevice(deviceId!));
    if (response != null) {
      final id = pick(response, 'data', 0, 'kar_registrasi').asStringOrNull();
      final karNik = pick(response, 'data', 0, 'kar_nik').asStringOrNull();

      if (id == deviceId) {
        _isLoggedIn = 'Masuk';
        _karNik = karNik;
      } else {
        _isLoggedIn = 'Ora';
      }
    } else {
      _isLoggedIn = 'Ora';
    }

    setState(() {
      _deviceId = deviceId;
      _isLoggedIn = _isLoggedIn;
      print("deviceId -> $_deviceId | login -> $_isLoggedIn | karNik -> $_karNik");
    });
  }

  @override
  void initState() {
    initPlatformState();
    super.initState();
    cekLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cekUpdateSaatMulai());
  }

  /// Tawarkan pembaruan setelah app tampil.
  ///
  /// Kalau server tidak bisa dihubungi, UpdateService.cekUpdate() mengembalikan null
  /// dan app tetap bisa dipakai - lebih baik tidak ada info update daripada semua
  /// orang terkunci gara-gara server mati.
  Future<void> _cekUpdateSaatMulai() async {
    final info = await UpdateService.cekUpdate();
    if (info == null || !mounted) return;
    if (info.wajib) {
      await showDialogUpdate(context, info);
    } else {
      _tawarkanUpdate(info);
    }
  }

  /// Info pembaruan yang tidak wajib: muncul sebagai dialog sekali saja, user
  /// boleh memilih "Nanti".
  void _tawarkanUpdate(InfoUpdate info) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ada versi baru',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          info.catatan.isEmpty
              ? 'Versi ${info.versionName} sudah tersedia.'
              : '${info.catatan}${info.versionName.isEmpty ? '' : '\n\nVersi ${info.versionName}.'}',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Nanti',
                style: GoogleFonts.inter(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              showDialogUpdate(context, info);
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF3B6DF0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Perbarui',
                style: GoogleFonts.inter(
                    fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
        fontFamily: GoogleFonts.montserrat().fontFamily,
      ),
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      home: _isLoggedIn == "Masuk" ? DashboardBaru() : HomePage(),
    );
  }
}