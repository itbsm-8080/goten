import 'package:goten/dashboard.dart';
import 'package:goten/widgets/cache_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart' as locationv2;
import 'package:trust_location/trust_location.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;
import 'package:one_clock/one_clock.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:deep_pick/deep_pick.dart';
import 'utils/device_utils.dart';
import 'dart:io' show Platform;
import 'services/absensi_service.dart';
import 'services/karyawan_service.dart';

class Absen extends StatefulWidget {
  final double? customLatitude;
  final double? customLongitude;
  final String? selectedUnitName;
  final String? karNik;
  final String? kdCabang;
  final String? namaKar;

  const Absen({
    Key? key,
    this.customLatitude,
    this.customLongitude,
    this.selectedUnitName,
    this.karNik,
    this.kdCabang,
    this.namaKar,
  }) : super(key: key);

  @override
  State<Absen> createState() => _AbsenState();
}

class _AbsenState extends State<Absen> {
  locationv2.Location lokasi = locationv2.Location();

  // Location variables
  double _latitude = 0;
  double _longitude = 0;
  double _latitude_absen = 0;
  double _longitude_absen = 0;
  String? _address;

  // Employee data
  String? _kdCabang;
  String? _karNik;
  String? _namaKar = "Nama";
  String? _namaUnit = "Unit";
  String? _deviceId;

  // UI state
  bool isLoading = true;
  bool isSubmittingCheckIn = false;
  bool isSubmittingCheckOut = false;
  final MapController _mapController = MapController();

  // Added: Status absensi hari ini
  String? lastCheckInTime;
  String? lastCheckOutTime;
  bool hasCheckedInToday = false;
  bool hasCheckedOutToday = false;

  @override
  void initState() {
    super.initState();

    _initializeData();
  }

  @override
  void dispose() {
    TrustLocation.stop();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _ambilData();
    await _checkTodayAttendanceStatus();
    await _requestPermission();
    await _getLocation();
  }

  Future<void> _ambilData() async {
    try {
      String? deviceId = await DeviceUtils.getDeviceId();
      if (deviceId == null) {
        _showErrorMessage('Gagal mendapatkan device ID');
        return;
      }

      // Prioritize data from widget parameters if available
      if (widget.karNik != null && widget.kdCabang != null && widget.namaKar != null) {
        print('Using data from widget parameters');

        setState(() {
          _deviceId = deviceId;
          _karNik = widget.karNik;
          _kdCabang = widget.kdCabang;
          _namaKar = widget.namaKar;

          // Use custom location if provided
          if (widget.customLatitude != null && widget.customLongitude != null) {
            _latitude = widget.customLatitude!;
            _longitude = widget.customLongitude!;
            print('Using custom location from dashboard');
          } else {
            // Fallback: get location from API
            _getLocationFromApi();
          }

          // Use custom unit name if provided
          if (widget.selectedUnitName != null) {
            _namaUnit = widget.selectedUnitName;
            print('Using custom unit name: $_namaUnit');
          }

          isLoading = false;
        });
      } else {
        print('Getting data from API (fallback)');
        // Fallback to API call if widget parameters not available
        await _getDataFromApi(deviceId);
      }
    } catch (e) {
      print('Error in _ambilData: $e');
      _showErrorMessage('Gagal memuat data');
    }
  }

  Future<void> _getDataFromApi(String deviceId) async {
    try {
      final karyawanData = await KaryawanService.getKaryawanByDevice(deviceId);
      if (karyawanData == null) {
        _showErrorMessage('Data karyawan tidak ditemukan');
        return;
      }

      final unitData = await KaryawanService.getUnitById(karyawanData['kar_kd_unit']);
      if (unitData == null) {
        _showErrorMessage('Data unit tidak ditemukan');
        return;
      }

      if (mounted) {
        setState(() {
          _deviceId = deviceId;
          // Use custom location if available, otherwise use API data
          _latitude = widget.customLatitude ?? unitData['latitude'] ?? 0.0;
          _longitude = widget.customLongitude ?? unitData['longitude'] ?? 0.0;
          _kdCabang = widget.kdCabang ?? karyawanData['kar_kd_unit'];
          _karNik = widget.karNik ?? karyawanData['kar_nik'];
          _namaKar = widget.namaKar ?? karyawanData['kar_nama'];
          _namaUnit = widget.selectedUnitName ?? unitData['nm_unit'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _getDataFromApi: $e');
      _showErrorMessage('Gagal memuat data dari API');
    }
  }

  Future<void> _getLocationFromApi() async {
    if (_kdCabang == null) return;

    try {
      final unitData = await KaryawanService.getUnitById(_kdCabang!);
      if (unitData != null && mounted) {
        setState(() {
          _latitude = unitData['latitude'] ?? 0.0;
          _longitude = unitData['longitude'] ?? 0.0;
          _namaUnit = unitData['nm_unit'];
        });
      }
    } catch (e) {
      print('Error getting location from API: $e');
    }
  }

  Future<void> _checkTodayAttendanceStatus() async {
    if (_namaKar == null) return;

    Map<String, String?> absensiData = {'masuk': null, 'keluar': null};
    absensiData = await AbsensiService.getAbsensiHariIni(_namaKar!);

    if (mounted) {
      setState(() {
        lastCheckInTime = absensiData['masuk'];
        lastCheckOutTime = absensiData['keluar'];
        hasCheckedInToday = absensiData['masuk'] != null;
        hasCheckedOutToday = absensiData['keluar'] != null;
      });
    }
  }

  double _hitungJarak(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    var jarakMeter = 12742 * asin(sqrt(a));
    return jarakMeter * 1000;
  }

  Future<void> _doCheckIn() async {
    if (_karNik == null || _kdCabang == null) {
      _showErrorMessage('Data karyawan tidak lengkap');
      return;
    }

    if (hasCheckedInToday) {
      _showErrorMessage('Anda sudah melakukan Check In hari ini');
      return;
    }

    setState(() {
      isSubmittingCheckIn = true;
    });

    try {
      double jarak = _hitungJarak(
        _latitude,  // Ini sekarang menggunakan lokasi dari dashboard (RotiQ)
        _longitude,
        _latitude_absen,
        _longitude_absen,
      );

      print('=== Check In Details ===');
      print('Target Location (from dashboard):');
      print('  Latitude: $_latitude');
      print('  Longitude: $_longitude');
      print('  Unit: $_namaUnit');
      print('Current Location:');
      print('  Latitude: $_latitude_absen');
      print('  Longitude: $_longitude_absen');
      print('Jarak Check In: ${jarak.toStringAsFixed(2)} meters');

      if (jarak >= 500.0) {
        _showErrorMessage('Lokasi absen tidak sesuai (jarak: ${jarak.toStringAsFixed(0)}m)');
        return;
      }

      String tanggal = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

      final success = await AbsensiService.submitAbsensi(
        karNik: _karNik!,
        tanggal: tanggal,
        kdCabang: _kdCabang!,
        latitude: _latitude_absen.toString(),
        longitude: _longitude_absen.toString(),
      );

      if (success) {
        _showSuccessMessage('Berhasil Check In di $_namaUnit');
        await _checkTodayAttendanceStatus();
      } else {
        _showErrorMessage('Check In gagal. Silakan coba lagi');
      }
    } catch (e) {
      print('Error in _doCheckIn: $e');
      _showErrorMessage('Terjadi kesalahan saat Check In');
    } finally {
      if (mounted) {
        setState(() {
          isSubmittingCheckIn = false;
        });
      }
    }
  }

  Future<void> _doCheckOut() async {
    if (_karNik == null || _kdCabang == null) {
      _showErrorMessage('Data karyawan tidak lengkap');
      return;
    }

    if (!hasCheckedInToday) {
      _showErrorMessage('Melakukan Check In otomatis sebelum Check Out...');
      await _doCheckIn();
      await Future.delayed(Duration(seconds: 2));
      await _checkTodayAttendanceStatus();

      if (!hasCheckedInToday) {
        _showErrorMessage('Gagal melakukan Check In otomatis');
        return;
      }
    }

    // if (hasCheckedOutToday) {
    //   _showErrorMessage('Anda sudah melakukan Check Out hari ini');
    //   return;
    // }

    setState(() {
      isSubmittingCheckOut = true;
    });

    try {
      double jarak = _hitungJarak(
        _latitude,
        _longitude,
        _latitude_absen,
        _longitude_absen,
      );

      print('Jarak Check Out: $jarak meters');

      if (jarak >= 500.0) {
        _showErrorMessage('Lokasi absen tidak sesuai (jarak: ${jarak.toStringAsFixed(0)}m)');
        return;
      }

      String tanggal = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

      final success = await AbsensiService.submitAbsensi(
        karNik: _karNik!,
        tanggal: tanggal,
        kdCabang: _kdCabang!,
        latitude: _latitude_absen.toString(),
        longitude: _longitude_absen.toString(),
      );

      if (success) {
        _showSuccessMessage('Berhasil Check Out');
        await _checkTodayAttendanceStatus(); // Refresh status
      } else {
        _showErrorMessage('Check Out gagal. Silakan coba lagi');
      }
    } catch (e) {
      print('Error in _doCheckOut: $e');
      _showErrorMessage('Terjadi kesalahan saat Check Out');
    } finally {
      if (mounted) {
        setState(() {
          isSubmittingCheckOut = false;
        });
      }
    }
  }

  Future<bool> _requestPermission() async {
    bool serviceEnabled;
    locationv2.PermissionStatus permissionGranted;

    serviceEnabled = await lokasi.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await lokasi.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    permissionGranted = await lokasi.hasPermission();
    if (permissionGranted == locationv2.PermissionStatus.denied) {
      permissionGranted = await lokasi.requestPermission();
      if (permissionGranted != locationv2.PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<void> _getLocation() async {
    final hasPermission = await _requestPermission();

    if (!hasPermission) {
      return _showPermissionDialog();
    }

    try {
      TrustLocation.start(5);

      TrustLocation.onChange.listen((values) {
        if (mounted) {
          setState(() {
            isLoading = false;
            _latitude_absen = double.parse(values.latitude.toString());
            _longitude_absen = double.parse(values.longitude.toString());

            _mapController.move(
              LatLng(_latitude_absen, _longitude_absen),
              13,
            );

            _getPlace();
          });
        }
      });
    } on PlatformException catch (e) {
      debugPrint('PlatformException $e');
      _showErrorMessage('Gagal mendapatkan lokasi');
    }
  }

  Future<void> _getPlace() async {
    try {
      List<Placemark> newPlace = await placemarkFromCoordinates(
        _latitude_absen,
        _longitude_absen,
      );

      if (newPlace.isNotEmpty) {
        Placemark placeMark = newPlace[0];
        String name = placeMark.name ?? '';
        String subLocality = placeMark.subLocality ?? '';
        String locality = placeMark.locality ?? '';
        String administrativeArea = placeMark.administrativeArea ?? '';
        String postalCode = placeMark.postalCode ?? '';
        String country = placeMark.country ?? '';
        String address = "$name, $subLocality, $locality, $administrativeArea $postalCode, $country";

        if (mounted) {
          setState(() {
            _address = address;
          });
        }
      }
    } catch (e) {
      print('Error getting place: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            "Tanpa izin penggunaan lokasi aplikasi ini tidak dapat digunakan dengan baik. Apa anda yakin menolak izin pengaktifan lokasi?",
          ),
          actions: [
            TextButton(
              child: const Text('COBA LAGI'),
              onPressed: () {
                Navigator.of(context).pop();
                _getLocation();
              },
            ),
            TextButton(
              child: const Text('SAYA YAKIN'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _displayMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_latitude_absen, _longitude_absen),
        initialZoom: 22.0,
        maxZoom: 30.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          maxZoom: 19,
          tileProvider: CachedTileProvider(),
        ),
        MarkerLayer(
          rotate: true,
          markers: [
            Marker(
              width: 30.0,
              height: 30.0,
              point: LatLng(_latitude_absen, _longitude_absen),
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.fmd_good,
                color: Colors.redAccent,
                size: 20.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Added: Widget for attendance status display
  Widget _buildAttendanceStatus() {
    if (isLoading) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Icon(
                hasCheckedInToday ? Icons.check_circle : Icons.radio_button_unchecked,
                color: hasCheckedInToday ? Colors.green : Colors.grey,
                size: 16,
              ),
              SizedBox(height: 4),
              Text(
                'Check In',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              if (hasCheckedInToday && lastCheckInTime != null)
                Text(
                  lastCheckInTime!.split(' ').length > 1
                      ? lastCheckInTime!.split(' ')[1]
                      : lastCheckInTime!,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
            ],
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),
          Column(
            children: [
              Icon(
                hasCheckedOutToday ? Icons.check_circle : Icons.radio_button_unchecked,
                color: hasCheckedOutToday ? Colors.orange : Colors.grey,
                size: 16,
              ),
              SizedBox(height: 4),
              Text(
                'Check Out',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              if (hasCheckedOutToday && lastCheckOutTime != null)
                Text(
                  lastCheckOutTime!.split(' ').length > 1
                      ? lastCheckOutTime!.split(' ')[1]
                      : lastCheckOutTime!,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Button
  Widget _buildDualButtons() {
    if (isLoading) return SizedBox.shrink();

    return Row(
      children: [
        // Check In Button
        Expanded(
          child: Container(
            height: 48,
            margin: EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              gradient: (isSubmittingCheckIn || hasCheckedInToday)
                  ? null
                  : LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: (isSubmittingCheckIn || hasCheckedInToday) ? null : [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (isSubmittingCheckIn || hasCheckedInToday)
                    ? Colors.grey.shade400
                    : Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (isSubmittingCheckIn || hasCheckedInToday)
                  ? null
                  : _doCheckIn,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSubmittingCheckIn)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      hasCheckedInToday ? Icons.check_circle : Icons.login,
                      size: 18,
                    ),
                  SizedBox(height: 2),
                  Text(
                    isSubmittingCheckIn
                        ? "..."
                        : hasCheckedInToday
                        ? "DONE"
                        : "CHECK IN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Check Out Button
        Expanded(
          child: Container(
            height: 48,
            margin: EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // (isSubmittingCheckOut || hasCheckedOutToday || !hasCheckedInToday)
              //     ? null
              //     : LinearGradient(
              //   colors: [Colors.orange.shade400, Colors.orange.shade600],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
              // (isSubmittingCheckOut || hasCheckedOutToday || !hasCheckedInToday) ? null : [
              //   BoxShadow(
              //     color: Colors.orange.withOpacity(0.3),
              //     spreadRadius: 0,
              //     blurRadius: 6,
              //     offset: Offset(0, 3),
              //   ),
              // ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                // (isSubmittingCheckOut || hasCheckedOutToday || !hasCheckedInToday)
                //     ? Colors.grey.shade400
                //     : Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _doCheckOut,
              // (isSubmittingCheckOut || hasCheckedOutToday || !hasCheckedInToday)
              //     ? null
              //     : _doCheckOut,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSubmittingCheckOut)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      Icons.logout,
                      // hasCheckedOutToday ? Icons.check_circle : Icons.logout,
                      size: 18,
                    ),
                  SizedBox(height: 2),
                  Text(
                    "CHECK OUT",
                    // isSubmittingCheckOut
                    //     ? "..."
                    //     : hasCheckedOutToday
                    //     ? "DONE"
                    //     : "CHECK OUT",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Map container (top half)
            Container(
              margin: const EdgeInsets.all(0),
              height: screenSize.height / 2,
              child: _displayMap(),
            ),

            // Bottom content container
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenSize.height / 2,
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Loading indicator
                      Visibility(
                        visible: isLoading,
                        child: const CircularProgressIndicator(
                          color: Colors.grey,
                        ),
                      ),

                      // Digital clock
                      Visibility(
                        visible: !isLoading,
                        child: DigitalClock.dark(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          datetime: DateTime.now(),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.all(Radius.zero),
                          ),
                          isLive: true,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Location info - Kompak
                      isLoading
                          ? const Text(
                        "Sedang mencari lokasi ...",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      )
                          : Text(
                        "Lat: $_latitude_absen, Long: $_longitude_absen",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Unit name & Employee name - Kompak
                      Visibility(
                        visible: !isLoading,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                _namaUnit ?? 'Unit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _namaKar ?? 'Nama',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Attendance status
                      _buildAttendanceStatus(),

                      const SizedBox(height: 8),

                      // Refresh location button - Lebih kecil
                      Visibility(
                        visible: !isLoading,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                                _address = "";
                              });
                              _getLocation();
                            },
                            icon: const Icon(Icons.my_location_outlined, size: 16),
                            label: const Text(
                              "Refresh Lokasi",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // REPLACED: Single absensi button with dual buttons
                      _buildDualButtons(),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}