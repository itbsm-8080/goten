import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/device_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'dashboard.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';

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
  static final String oneSignalAppId = "e82ad139-8162-46bd-989f-82f42dfb474e";

  Future<void> initPlatformState() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addClickListener((event) {
      print("Notifikasi dibuka: ${event.notification.jsonRepresentation()}");
    });
  }

  Future<void> cekLogin() async {
    String? deviceId;
    String? isLoggedIn;

    try {
      deviceId = await DeviceUtils.getDeviceId(); // Gunakan utility
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
      final id =
      pick(response, 'data', 0, 'kar_registrasi').asStringOrNull();

      if (id == deviceId) {
        isLoggedIn = 'Masuk';
      } else {
        isLoggedIn = 'Ora';
      }
    } else {
      isLoggedIn = 'Ora'; // kalau gagal API dianggap belum login
    }

    setState(() {
      _deviceId = deviceId;
      _isLoggedIn = isLoggedIn;
      print("deviceId -> $_deviceId | login -> $_isLoggedIn");
    });
  }

  @override
  void initState() {
    initPlatformState();
    super.initState();
    cekLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
        fontFamily: GoogleFonts.montserrat().fontFamily,
      ),
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      home: _isLoggedIn == "Masuk" ? Dashboard() : HomePage(),
    );
  }
}