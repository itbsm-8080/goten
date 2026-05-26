import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:goten/history.dart';
import 'package:goten/statistik.dart';
import 'absen.dart';
import 'dart:convert';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'utils/device_utils.dart';
import 'dart:io' show Platform;
// import 'package:flutter/system.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gravatar/utils.dart';
import 'package:one_clock/one_clock.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/absensi_service.dart';
import 'services/karyawan_service.dart';
import 'services/jabatan_service.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:goten/model/unit.dart';
import 'package:goten/services/unit_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final TextStyle whiteText = TextStyle(color: Colors.white);

  String tanggal = '';
  String tglIndo = '';
  String? _kdCabang;
  String? _karNik;
  String _karJabatan = "Jabatan";
  String? _namaKar = "Nama";
  String? _namaUnit = "Unit";
  double _latitude = 0;
  double _longitude = 0;
  String? _masuk;
  String? _keluar;
  String? _deviceId;
  bool _isLoading = true;
  int _selectedIndex = 0;

  bool _isRotiQEmployee = false;
  List<Units> _rotiQUnits = [];
  Units? _selectedRotiQUnit;

  double? _absenLatitude;
  double? _absenLongitude;
  String? _absenUnitName;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await initializeDateFormatting();
    tanggal = DateTime.now().toString();
    setState(() {
      tglIndo = DateFormat.yMMMMEEEEd('id')
          .format(DateTime.parse(tanggal))
          .toString();
    });

    await _ambilData();
  }

  Future<void> _ambilData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? deviceId = await DeviceUtils.getDeviceId();
      if (deviceId == null) {
        _showError('Gagal mendapatkan device ID');
        return;
      }

      final karyawanData = await KaryawanService.getKaryawanByDevice(deviceId);
      if (karyawanData == null) {
        _showError('Data karyawan tidak ditemukan');
        return;
      }

      final karNik = karyawanData['kar_nik'];
      final karKdUnit = karyawanData['kar_kd_unit'];
      final karNama = karyawanData['kar_nama'];
      final karKdJabat = karyawanData['kar_kd_jabat'];

      String? karNamaJabat;
      if (karKdJabat != null) {
        karNamaJabat = await JabatanService.getJabatanByKode(karKdJabat);
      }

      final unitData = await KaryawanService.getUnitById(karKdUnit ?? '');

      Map<String, String?> absensiData = {'masuk': null, 'keluar': null};
      if (karNama != null) {
        absensiData = await AbsensiService.getAbsensiHariIni(karNama);
      }

      if (mounted) {
        setState(() {
          _deviceId = deviceId;
          _latitude = unitData?['latitude'] ?? 0.0;
          _longitude = unitData?['longitude'] ?? 0.0;
          _kdCabang = karKdUnit;
          _karNik = karNik;
          _karJabatan = karNamaJabat ?? "Jabatan";
          _namaKar = karNama ?? "Nama";
          _namaUnit = unitData?['nm_unit'] ?? "Unit";
          _masuk = absensiData['masuk'];
          _keluar = absensiData['keluar'];

          _absenLatitude = unitData?['latitude'] ?? 0.0;
          _absenLongitude = unitData?['longitude'] ?? 0.0;
          _absenUnitName = unitData?['nm_unit'] ?? "Unit";

          _isLoading = false;
        });

        print("nama unit: $unitData?['nm_unit']");

        await _checkAndLoadRotiQUnits();
      }
    } catch (e) {
      print('Error in _ambilData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Gagal memuat data dashboard');
      }
    }
  }

  void _updateAbsenLocation(Units unit) {
    if (mounted) {
      setState(() {
        _selectedRotiQUnit = unit;
        _latitude = unit.latitude;
        _longitude = unit.longitude;

        // Store for Absen screen
        _absenLatitude = unit.latitude;
        _absenLongitude = unit.longitude;
        _absenUnitName = unit.nmUnit;

        print('Updated values:');
        print('  _selectedRotiQUnit: ${_selectedRotiQUnit?.nmUnit}');
        print('  _latitude: $_latitude');
        print('  _longitude: $_longitude');
        print('  _absenLatitude: $_absenLatitude');
        print('  _absenLongitude: $_absenLongitude');
        print('  _absenUnitName: $_absenUnitName');
      });
    }
  }

  Future<void> _checkAndLoadRotiQUnits() async {
    print('=== _checkAndLoadRotiQUnits() START ===');
    print('_namaUnit: $_namaUnit');

    // Cek apakah employee dari RotiQ
    if (_namaUnit != null && _namaUnit!.toLowerCase().contains('rotiq')) {
      print('Employee is from RotiQ unit');

      if (mounted) {
        setState(() {
          _isRotiQEmployee = true;
        });
      }

      try {
        // Dapatkan units dari API
        final units = await UnitService.getRotiQUnits();
        print('Got ${units.length} units from API');

        // INI YANG PERLU DITAMBAHKAN: setState() untuk mengisi _rotiQUnits
        if (mounted) {
          setState(() {
            _rotiQUnits = units;  // <-- INI YANG HILANG!
            print('_rotiQUnits now has ${_rotiQUnits.length} items');
          });
        }

        if (mounted && units.isNotEmpty) {
          Units? defaultUnit;
          try {
            defaultUnit = units.firstWhere(
                    (unit) => unit.kdUnit == _kdCabang
            );
            print('Found matching unit: ${defaultUnit.nmUnit}');
          } catch (e) {
            defaultUnit = units.first;
            print('Using first unit: ${defaultUnit.nmUnit}');
          }

          if (defaultUnit != null && mounted) {
            _updateAbsenLocation(defaultUnit);

            // Juga set _selectedRotiQUnit
            setState(() {
              _selectedRotiQUnit = defaultUnit;
            });
          }
        } else {
          print('No RotiQ units found or units is empty');
        }

      } catch (e) {
        print('Error loading RotiQ units: $e');
      }
    } else {
      print('Employee is NOT from RotiQ. namaUnit: $_namaUnit');
    }
    print('=== _checkAndLoadRotiQUnits() END ===');
  }

  void _showError(String message) {
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

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildBody(context);
      case 1:
        return Absen(
          customLatitude: _absenLatitude ?? _latitude,
          customLongitude: _absenLongitude ?? _longitude,
          selectedUnitName: _absenUnitName ?? _namaUnit,
          karNik: _karNik,
          kdCabang: _kdCabang,
          namaKar: _namaKar,
        );
      case 2:
        return History();
      default:
        return _buildBody(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GNav(
              gap: 8,
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 0) {
                    _ambilData();
                  }
                });
              },
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: Colors.white,
              color: Colors.grey[600],
              activeColor: Colors.white,
              tabBackgroundGradient: const LinearGradient(
                colors: [Colors.blue, Colors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              tabs: const [
                GButton(icon: Icons.home, text: 'Dashboard'),
                GButton(icon: Icons.fingerprint, text: 'Absen'),
                GButton(icon: Icons.list, text: 'History'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Memuat data dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _ambilData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildEnhancedHeader(),

            // Welcome back section
            Container(
              margin: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.waving_hand,
                        color: Colors.amber.shade600,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Selamat datang kembali!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    _namaUnit ?? 'Unit',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Date and clock card
            _buildEnhancedClockCard(),

            SizedBox(height: 16),

            // ROTIQ LOCATION SELECTOR - Placed here as requested
            if (_isRotiQEmployee) _buildRotiQLocationSelector(),

            SizedBox(height: 16),

            // Attendance status section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Status Absensi Hari Ini",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Enhanced attendance cards
            _buildEnhancedAttendanceCards(),

            SizedBox(height: 16),

            // Action cards section
            _buildActionCards(),

            SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildRotiQLocationSelector() {
    print("APAKAH AKU");
    print(_rotiQUnits);
    if (!_isRotiQEmployee || _rotiQUnits.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.orange.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.store,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi RotiQ Saat Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Units>(
                    value: _selectedRotiQUnit,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.orange.shade700),
                    iconSize: 30,
                    elevation: 2,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                    dropdownColor: Colors.white,
                    onChanged: (Units? newUnit) {
                      if (newUnit != null && mounted) {
                        // Use the new update function
                        _updateAbsenLocation(newUnit);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lokasi absensi diubah ke ${newUnit.nmUnit}'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    items: _rotiQUnits.map((Units unit) {
                      return DropdownMenuItem<Units>(
                        value: unit,
                        child: Text(
                          unit.nmUnit,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return _rotiQUnits.map<Widget>((Units unit) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            unit.nmUnit,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 50.0, 0, 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.0),
          bottomRight: Radius.circular(30.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: Text(
              "Dashboard",
              style: whiteText.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: Image.asset(
                  'assets/user.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _namaKar ?? 'Nama',
                  style: whiteText.copyWith(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _karJabatan,
                    style: whiteText.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedClockCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Hari Ini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              tglIndo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: DigitalClock.dark(
                padding: EdgeInsets.zero,
                datetime: DateTime.now(),
                decoration: BoxDecoration(),
                isLive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAttendanceCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildAttendanceCard(
              title: 'Check In',
              status: _masuk != null,
              time: _masuk,
              icon: Icons.login,
              color: Colors.green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildAttendanceCard(
              title: 'Check Out',
              status: _keluar != null,
              time: _keluar,
              icon: Icons.logout,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({
    required String title,
    required bool status,
    required String? time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: status ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status ? Icons.check_circle : icon,
              color: status ? color : Colors.grey,
              size: 28,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            status ? 'Selesai' : 'Belum',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: status ? color : Colors.grey.shade600,
            ),
          ),
          if (status && time != null) ...[
            SizedBox(height: 4),
            Text(
              time!.length > 8 ? time!.split(' ').last : time!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize,
                color: Colors.blue.shade600,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Menu Lainnya",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_graph_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                "Statistik Kehadiran",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              subtitle: Text(
                "Lihat ringkasan kehadiran bulan ini",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              trailing: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue.shade600,
                  size: 16,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Statistik(nama: _namaKar),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}