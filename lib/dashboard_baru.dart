import 'package:flutter/material.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:goten/history.dart';
import 'package:goten/statistik.dart';
import 'package:goten/services/absensi_service.dart';
import 'package:goten/services/karyawan_service.dart';
import 'package:goten/services/jabatan_service.dart';
import 'package:goten/utils/device_utils.dart';
import 'package:location/location.dart' as locationv2;
import 'package:trust_location/trust_location.dart';
import 'package:geocoding/geocoding.dart';
import 'izin_page.dart';
import 'laporan_izin_page.dart';
import 'package:flutter/services.dart';
import 'services/izin_service.dart';
import 'approval_izin_page.dart';
import 'approval_lembur_page.dart';
import 'pod_page.dart';
import 'widgets/shift_dialog.dart';
import 'config/app_version.dart';
import 'config/radius_absen.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

class DashboardBaru extends StatefulWidget {
  const DashboardBaru({super.key});

  @override
  State<DashboardBaru> createState() => _DashboardBaruState();
}

class _DashboardBaruState extends State<DashboardBaru> {
  String? _karNik;
  String? _kdCabang;
  String? _namaKar = "Nama Karyawan";
  String? _namaUnit = "Unit";
  String? _karJabatan = "Jabatan";
  String? _karKdJabat;
  String? _masuk;
  String? _keluar;
  List<Map<String, dynamic>> _sesiList = [];
  List<String>? _sesiTampilTanggal;
  List _shiftList = [];
  int? _selectedShift;
  List<String> _kdUnits = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isApprover = false;

  locationv2.Location lokasi = locationv2.Location();
  double _latitude = 0;
  double _longitude = 0;
  double _latitudeAbsen = 0;
  double _longitudeAbsen = 0;
  String? _address;
  String _dayName = '';
  String _dateNumber = '';
  String _monthYear = '';
  String _kdUnitApprover = '';
  int _pendingIzin = 0;
  int _pendingLembur = 0;

  int _sisaCuti = 0;

  bool _isRotiQMobile = false;
  List<Map<String, dynamic>> _rotiQUnits = [];
  Map<String, dynamic>? _selectedRotiQUnit;

  // Akunting unit 18: boleh absen di cabang BSM mana pun (titik acuan = cabang dipilih).
  bool _isAkunting = false;
  List<Map<String, dynamic>> _cabangUnits = [];
  Map<String, dynamic>? _selectedCabangUnit;

  // ========== PALETTE ==========
  static const Color bg = Color(0xFFF0F4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF1B1B2F);
  static const Color textSub = Color(0xFF5A5A7A);
  static const Color textLight = Color(0xFF9090A8);
  static const Color border = Color(0xFFE8ECF4);
  static const Color primaryBlue = Color(0xFF3B6DF0);
  static const Color accentCoral = Color(0xFFFF5E62);
  static const Color successGreen = Color(0xFF00C897);
  static const Color warningOrange = Color(0xFFFF8C42);
  static const Color purple = Color(0xFF7C3AED);
  static const Color teal = Color(0xFF00B4D8);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    TrustLocation.stop();
    super.dispose();
  }

  Future<void> _init() async {
    await initializeDateFormatting('id');
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _dayName = DateFormat('EEEE', 'id').format(now);
        _dateNumber = DateFormat('dd', 'id').format(now);
        _monthYear = DateFormat('MMM yyyy', 'id').format(now);
      });
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      String? deviceId = await DeviceUtils.getDeviceId();
      if (deviceId == null) { _showMsg('Gagal mendapatkan device ID', true); return; }

      final kar = await KaryawanService.getKaryawanByDevice(deviceId);
      if (kar == null) { _showMsg('Data tidak ditemukan', true); return; }

      final unit = await KaryawanService.getUnitById(kar['kar_kd_unit'] ?? '');
      String? jabat;
      if (kar['kar_kd_jabat'] != null) jabat = await JabatanService.getJabatanByKode(kar['kar_kd_jabat']);

      Map<String, dynamic> absen = {'sessions': <Map<String, dynamic>>[]};
      if (kar['kar_nama'] != null) absen = await AbsensiService.getAbsensiHariIni(kar['kar_nama']);

      await _requestPermission();
      _startLocation();

      if (mounted) {
        setState(() {
          _latitude = unit?['latitude'] ?? 0;
          _longitude = unit?['longitude'] ?? 0;
          _kdCabang = kar['kar_kd_unit'];
          _karNik = kar['kar_nik'];
          _karJabatan = jabat ?? 'Jabatan';
          _karKdJabat = kar['kar_kd_jabat'];
          _namaKar = kar['kar_nama'] ?? 'Nama';
          _namaUnit = unit?['nm_unit'] ?? 'Unit';
          _sesiList = (absen['sessions'] as List?)?.cast<Map<String, dynamic>>().toList() ?? [];
          _sesiTampilTanggal = (absen['sesi_tampil'] as List?)?.cast<String>();
          _isLoading = false;
        });
      }

      // Daftar shift hanya untuk cabang 20. Default dari server.
      if (_isShiftUser) {
        try {
          final shiftData = await AbsensiService.getShifts(_karNik!);
          if (mounted && shiftData != null && shiftData['data'] is List) {
            setState(() {
              _shiftList = shiftData['data'] as List;
            });
          }
        } catch (e) {
          print('Error ambil daftar shift: $e');
        }
      }

      _applyShiftDisplay();

      // Ambil sisa cuti
      if (_karNik != null) {
        try {
          final cutiResponse = await IzinService.getSisaCuti(_karNik!);
          if (mounted && cutiResponse != null) {
            setState(() {
              _sisaCuti = cutiResponse['sisa_cuti'] ?? 0;
            });
          }
        } catch (e) {
          print('Error ambil sisa cuti: $e');
        }
      }

      // Cek role approval
      if (mounted && _karNik != null) {
        try {
          final roleResponse = await IzinService.cekRoleApproval(_karNik!);
          if (mounted && roleResponse != null) {
            final isApprover = roleResponse['is_approver'] ?? false;
            final kdUnits = (roleResponse['kd_units'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final pending = roleResponse['pending'] as Map?;

            if (mounted) {
              setState(() {
                _isApprover = isApprover;
                _kdUnits = kdUnits;
                _pendingIzin = (pending?['izin'] as num?)?.toInt() ?? 0;
                _pendingLembur = (pending?['lembur'] as num?)?.toInt() ?? 0;
              });
            }
          }
        } catch (e) {
          print('Error cek role: $e');
        }
      }

      // Cek RotiQ Mobile / akunting lintas cabang BSM
      try {
        final rotiqResponse = await IzinService.cekRotiQMobile(_karNik!);
        if (mounted && rotiqResponse != null) {
          final isRotiQMobile = rotiqResponse['is_rotiq_mobile'] ?? false;
          final isAkunting = rotiqResponse['is_akunting'] ?? false;
          final units = (rotiqResponse['units'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          setState(() {
            _isRotiQMobile = isRotiQMobile;
            _rotiQUnits = units;
            if (!isRotiQMobile) {
              _selectedRotiQUnit = null;
            }
            _isAkunting = isAkunting;
            _cabangUnits = units;
            _selectedCabangUnit = null;
            if (isAkunting) {
              for (final u in units) {
                if (u['kd_unit'].toString() == (_kdCabang ?? '')) {
                  _selectedCabangUnit = u;
                  break;
                }
              }
              if (_selectedCabangUnit == null && units.isNotEmpty) _selectedCabangUnit = units.first;
            }
          });
        }
      } catch (e) {
        print('Error cek RotiQ: $e');
      }

    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _showMsg('Gagal memuat data', true); }
    }
  }

  // ========== HELPER FUNCTIONS ==========

  bool get _isPODMenu => _karKdJabat == '21' || _karKdJabat == '30';

  String _jamShift(int? kd) {
    for (final s in _shiftList) {
      if (s['kd_shift'] == kd) {
        final mulai = s['jam_mulai'];
        final selesai = s['jam_selesai'];
        if (mulai != null && selesai != null) return '$mulai - $selesai';
      }
    }
    switch (kd) {
      case 1: return '07:00 - 15:00';
      case 2: return '15:00 - 23:00';
      case 3: return '23:00 - 07:00';
      default: return '';
    }
  }

  String _getShiftName(int? shift) {
    switch (shift) {
      case 0: return 'Day Shift';
      case 1: return 'Pagi (${_jamShift(shift)})';
      case 2: return 'Siang (${_jamShift(shift)})';
      case 3: return 'Malam (${_jamShift(shift)})';
      default: return '';
    }
  }

  // Cabang 20 saja yang punya pilihan shift. Jabatan tidak dibatasi.
  // kar_kd_unit bisa string atau int tergantung driver MySQL.
  bool get _isShiftUser => _kdCabang?.toString() == '20';

  // Hari Minggu hanya Day Shift, jadi pemilih shift disembunyikan.
  bool get _isMinggu => _dayName.toLowerCase() == 'minggu';

  bool get _showShiftPicker => _isShiftUser && !_isMinggu;

  // Work date yang boleh tampil di kartu, ditentukan server lewat sesi_tampil
  // (hari ini + sesi yang belum keluar dan belum lewat batas reset 01:00/09:00).
  // Client tidak ikut menghitung aturan itu supaya tidak melenceng.
  Set<String> get _tampilTanggal =>
      (_sesiTampilTanggal ?? const <String>{}).toSet();

  List<Map<String, dynamic>> get _sesiAktif => _sesiList
      .where((s) => _tampilTanggal.contains(s['tanggal_kerja']))
      .toList();

  // Shift yang punya check-in tapi belum ada check-out, sesi aktif saja.
  List<int> get _openShift {
    final list = <int>[];
    for (final s in _sesiAktif) {
      if (s['masuk'] != null && s['keluar'] == null) {
        final kd = (s['shift'] as num?)?.toInt() ?? 0;
        if (!list.contains(kd)) list.add(kd);
      }
    }
    return list;
  }

  // Shift yang bisa di-check-out: yang punya check-in, terbuka atau sudah tertutup.
  // Sesi yang sudah keluar masih boleh ditutup lagi (batas 3x / 10 jam di server).
  List<int> get _checkOutShift {
    final list = <int>[];
    for (final s in _sesiAktif) {
      if (s['masuk'] != null) {
        final kd = (s['shift'] as num?)?.toInt() ?? 0;
        if (!list.contains(kd)) list.add(kd);
      }
    }
    return list;
  }

  // Shift untuk tampilan: yang sedang dipilih, fallback ke sesi terbuka terakhir.
  int get _displayShift => _selectedShift ?? (_openShift.isNotEmpty ? _openShift.last : 0);

  // Tampilan MASUK/KELUAR mengikuti shift yang dipilih. Server mengirim sesi
  // terbaru lebih dulu, jadi yang pertama cocok adalah sesi terbaru.
  void _applyShiftDisplay() {
    if (!mounted) return;
    final target = _displayShift;
    Map<String, dynamic>? sesi;
    for (final s in _sesiAktif) {
      if ((s['shift'] as num?)?.toInt() == target) {
        sesi = s;
        break;
      }
    }

    setState(() {
      _masuk = sesi?['masuk'] as String?;
      _keluar = sesi?['keluar'] as String?;
    });
  }

  Future<bool> _requestPermission() async {
    bool svc = await lokasi.serviceEnabled();
    if (!svc) svc = await lokasi.requestService();
    if (!svc) return false;
    var perm = await lokasi.hasPermission();
    if (perm == locationv2.PermissionStatus.denied) {
      perm = await lokasi.requestPermission();
      if (perm != locationv2.PermissionStatus.granted) return false;
    }
    return true;
  }

  void _startLocation() {
    try {
      TrustLocation.start(5);
      TrustLocation.onChange.listen((v) {
        if (mounted) {
          setState(() {
            _latitudeAbsen = double.parse(v.latitude.toString());
            _longitudeAbsen = double.parse(v.longitude.toString());
          });
          _getPlace();
        }
      });
    } catch (_) {}
  }

  Future<void> _getPlace() async {
    try {
      final pm = await placemarkFromCoordinates(_latitudeAbsen, _longitudeAbsen);
      if (pm.isNotEmpty && mounted) {
        setState(() => _address = [pm[0].street, pm[0].subLocality, pm[0].locality].where((e) => e != null && e.isNotEmpty).join(', '));
      }
    } catch (_) {}
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

  // Jarak GPS HP ke titik absen. _latitude/_longitude sudah mengikuti unit RotiQ
  // yang dipilih (lihat _pilihUnitRotiQ), jadi jadi acuan yang benar.
  String? _cekJangkauan() {
    if (_latitude == 0 && _longitude == 0) return null;
    if (_latitudeAbsen == 0 && _longitudeAbsen == 0) {
      return 'Lokasi GPS belum siap, coba beberapa saat lagi';
    }
    final jarak = _hitungJarak(_latitudeAbsen, _longitudeAbsen, _latitude, _longitude);
    if (jarak >= radiusAbsenMeter) {
      return 'Lokasi absen tidak sesuai (jarak: ${jarak.toStringAsFixed(0)}m)';
    }
    return null;
  }

  // Status berasal dari tombol yang ditekan, bukan dari state tampilan.
  Future<void> _doAbsensi(int status) async {
    if (_karNik == null || _kdCabang == null) { _showMsg('Data tidak lengkap', true); return; }
    final luarJangkauan = _cekJangkauan();
    if (luarJangkauan != null) { _showMsg(luarJangkauan, true); return; }
    setState(() => _isSubmitting = true);
    try {
      final aksi = status == 1 ? 'Check In' : 'Check Out';

      AbsensiResult result;
      if (_showShiftPicker) {
        // Cabang 20: pilih shift dulu di dialog, lalu submit.
        result = await submitAbsensiWithShift(
          context,
          aksi: aksi,
          karNik: _karNik!,
          kdCabang: _kdCabang!,
          latitude: _latitudeAbsen.toString(),
          longitude: _longitudeAbsen.toString(),
          status: status,
          openShift: _checkOutShift,
        );
      } else {
        // Cabang lain / hari Minggu: langsung submit dengan Day Shift.
        // Akunting lintas cabang BSM: titik acuan divalidasi server terhadap cabang dipilih.
        result = await AbsensiService.submitAbsensi(
          karNik: _karNik!,
          kdCabang: _kdCabang!,
          latitude: _latitudeAbsen.toString(),
          longitude: _longitudeAbsen.toString(),
          status: status,
          shift: 0,
          kdUnit: _isAkunting && _selectedCabangUnit != null
              ? _selectedCabangUnit!['kd_unit'].toString()
              : null,
        );
      }

      if (result.code == 'cancelled') return;

      if (result.success) {
        final namaShift = result.shift == 0 ? 'Day Shift' : 'Shift ${result.shift}';
        final akhir = result.terlambat ? ' (terlambat)' : '';
        // Check-out yang mengoreksi tap sebelumnya diberi tahu ke user.
        _showMsg(result.perbaikan
            ? '$aksi $namaShift diperbarui'
            : '$aksi $namaShift berhasil$akhir', false);
        final a = await AbsensiService.getAbsensiHariIni(_namaKar!);
        if (mounted) {
          setState(() {
            _sesiList = (a['sessions'] as List?)?.cast<Map<String, dynamic>>().toList() ?? [];
            _sesiTampilTanggal = (a['sesi_tampil'] as List?)?.cast<String>();
          });
          _applyShiftDisplay();
        }
      } else {
        _showMsg(result.message, true);
      }
    } catch (_) {
      _showMsg('Error', true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMsg(String msg, bool err) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: err ? accentCoral : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _showUnitPicker(
    List<Map<String, dynamic>> units,
    Map<String, dynamic>? selected,
    void Function(Map<String, dynamic> unit) onPick,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(top: 16, bottom: 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Pilih Lokasi Absen', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
            ),
            SizedBox(height: 12),
            ...(units.map((unit) => ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: selected?['kd_unit'] == unit['kd_unit'] ? successGreen.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store,
                  size: 18,
                  color: selected?['kd_unit'] == unit['kd_unit'] ? successGreen : textLight,
                ),
              ),
              title: Text(unit['nm_unit'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textMain)),
              trailing: selected?['kd_unit'] == unit['kd_unit']
                  ? Icon(Icons.check_circle, color: successGreen, size: 22)
                  : null,
              onTap: () {
                setState(() => onPick(unit));
                Navigator.pop(ctx);
                _showMsg('Lokasi absen: ${unit['nm_unit']}', false);
              },
            ))),
          ],
        ),
      ),
    );
  }

  // Titik acuan absen: cabang BSM yang dipilih (akunting), unit RotiQ, atau unit asal.
  void _pilihTitikAbsen(Map<String, dynamic> unit) {
    _latitude = double.tryParse(unit['latitude']?.toString() ?? '0') ?? 0;
    _longitude = double.tryParse(unit['longitude']?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: bg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: primaryBlue,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                _profileCard(),
                SizedBox(height: 16),
                _menuGrid(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== PROFILE + ABSENSI CARD ==========
  Widget _profileCard() {
    // Sesi yang ditampilkan mengikuti shift terpilih. Sesi terbuka selalu bisa ditutup,
    // jadi Check Out aktif selama masih ada shift yang belum keluar.
    // Sesi yang sudah keluar dihitung selesai, jadi Check In aktif lagi.
    // Hanya sesi yang masih terbuka (belum check-out) yang mengunci tombol.
    bool inDone = _masuk != null && _keluar == null;
    bool outDone = _keluar != null;
    // Cabang 20: shift terkunci kalau sesinya masih terbuka, bukan kalau pernah check-in.
    bool bisaCheckIn = !_showShiftPicker ? !inDone : !_openShift.contains(_displayShift);
    bool bisaCheckOut = !_showShiftPicker ? !inDone || !outDone : _checkOutShift.isNotEmpty;
    Color accentColor = outDone ? successGreen : (inDone ? warningOrange : accentCoral);
    String status = outDone ? 'Selesai' : (inDone ? 'Aktif' : 'Belum Absen');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: successGreen.withOpacity(0.15), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00A86B), Color(0xFF00855A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(right: -30, top: -40, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
              Positioned(left: -20, bottom: -20, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),

              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    // ===== PROFILE ROW =====
                    Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: Offset(0, 2))],
                            image: DecorationImage(image: AssetImage('assets/user.png'), fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_namaKar ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                              SizedBox(height: 3),
                              _badgeCompact(Icons.badge, _karJabatan ?? ''),
                              SizedBox(height: 2),
                              _badgeCompact(Icons.apartment, _namaUnit ?? ''),
                              // RotiQ Location Picker
                              if (_isRotiQMobile && _rotiQUnits.isNotEmpty) ...[
                                SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showUnitPicker(_rotiQUnits, _selectedRotiQUnit, (u) {
                                    _selectedRotiQUnit = u;
                                    _pilihTitikAbsen(u);
                                  }),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.swap_horiz, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _selectedRotiQUnit?['nm_unit'] ?? 'Pilih Lokasi Absen',
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              // Lokasi cabang absen (akunting lintas cabang BSM)
                              if (_isAkunting && _cabangUnits.isNotEmpty) ...[
                                SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showUnitPicker(_cabangUnits, _selectedCabangUnit, (u) {
                                    _selectedCabangUnit = u;
                                    _pilihTitikAbsen(u);
                                  }),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.business, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _selectedCabangUnit?['nm_unit'] ?? 'Pilih Lokasi Absen',
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              // Shift selector. Sheet yang sama dipakai saat submit,
                              // jadi di sini hanya read-only (satu sumber kebenaran).
                              if (_showShiftPicker) ...[
                                SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => showShiftDialog(
                                    context,
                                    aksi: _masuk == null ? 'Check In' : 'Check Out',
                                    karNik: _karNik!,
                                    openShift: _checkOutShift,
                                    status: _masuk == null ? 1 : 2,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.schedule, size: 14, color: Colors.white),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Shift ${_displayShift == 0 ? '' : '$_displayShift — '}${_getShiftName(_displayShift)}',
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        // Sisa Cuti
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$_sisaCuti', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF00A86B), height: 1)),
                              Text('Sisa Cuti', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF00A86B).withOpacity(0.7))),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),
                    Container(height: 1, color: Colors.white.withOpacity(0.2)),
                    SizedBox(height: 12),

                    // ===== ABSENSI SECTION =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Absensi Hari Ini', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.9))),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text(status, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Time slots
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text('MASUK', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                                SizedBox(height: 3),
                                Text(
                                  inDone && _masuk != null ? (_masuk!.contains(' ') ? _masuk!.split(' ').last : _masuk!) : '--:--',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text('KELUAR', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                                SizedBox(height: 3),
                                Text(
                                  outDone && _keluar != null ? (_keluar!.contains(' ') ? _keluar!.split(' ').last : _keluar!) : '--:--',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Shift badge (hanya unit 20)
                    // if (_kdCabang == '20' && _shift != null) ...[
                    //   SizedBox(height: 10),
                    //   Container(
                    //     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    //     decoration: BoxDecoration(
                    //       color: Colors.white.withOpacity(0.15),
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Icon(Icons.schedule, size: 12, color: Colors.white),
                    //         SizedBox(width: 6),
                    //         Text(
                    //           'Shift $_shift — ${_shiftName ?? ''}',
                    //           style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ],

                    SizedBox(height: 10),

                    // Location
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.white.withOpacity(0.6)),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _address ?? 'Mencari lokasi...',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() { _address = 'Memperbarui...'; });
                              _startLocation();
                            },
                            child: Icon(Icons.refresh_rounded, size: 16, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    // Buttons. Status dikirim per tombol, bukan ditebak dari tampilan.
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: (inDone || !bisaCheckIn || _isSubmitting) ? null : () => _doAbsensi(1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF00A86B),
                                disabledBackgroundColor: Colors.white.withOpacity(0.15),
                                disabledForegroundColor: Colors.white.withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: _isSubmitting && !inDone
                                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF00A86B), strokeWidth: 2))
                                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.login, size: 16),
                                SizedBox(width: 4),
                                Text('CHECK IN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ]),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: (!bisaCheckOut || _isSubmitting) ? null : () => _doAbsensi(2),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF00A86B),
                                disabledBackgroundColor: Colors.white.withOpacity(0.15),
                                disabledForegroundColor: Colors.white.withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: _isSubmitting && inDone
                                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF00A86B), strokeWidth: 2))
                                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.logout, size: 16),
                                SizedBox(width: 4),
                                Text('CHECK OUT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeCompact(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white.withOpacity(0.8)),
        SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85)),
        ),
      ],
    );
  }

  /// Periksa pembaruan atas permintaan user. Berbeda dengan cek otomatis saat app
  /// dibuka: di sini "tidak ada update" juga perlu diberi tahu.
  Future<void> _cekUpdate() async {
    if (!appVersiDiketahui) {
      _showMsg('Versi aplikasi belum-known (build tanpa APP_VERSION_CODE)', true);
      return;
    }
    _showMsg('Mencari pembaruan...', false);
    final info = await UpdateService.cekUpdate();
    if (!mounted) return;
    if (info == null) {
      _showMsg('Sudah versi terbaru ($appVersiTampil)', false);
      return;
    }
    await showDialogUpdate(context, info);
  }

  // ========== MENU GRID ==========
  Widget _menuGrid() {
    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'History',
        'subtitle': 'Riwayat',
        'color': Color(0xFF3B6DF0),
        'gradient': [Color(0xFF3B6DF0), Color(0xFF5B8AF7)],
        'page': History()
      },
      {
        'icon': Icons.edit_calendar_rounded,
        'label': 'Izin',
        'subtitle': 'Pengajuan',
        'color': Color(0xFFFF5E62),
        'gradient': [Color(0xFFFF5E62), Color(0xFFFF7F82)],
        'page': IzinPage(karNik: _karNik)
      },
      {
        'icon': Icons.folder_open_rounded,
        'label': 'Laporan',
        'subtitle': 'Status',
        'color': Color(0xFF00C897),
        'gradient': [Color(0xFF00C897), Color(0xFF33D4B0)],
        'page': LaporanIzinPage(karNik: _karNik)
      },
      {
        'icon': Icons.insights_rounded,
        'label': 'Statistik',
        'subtitle': 'Performa',
        'color': Color(0xFF7C3AED),
        'gradient': [Color(0xFF7C3AED), Color(0xFF9B6DF0)],
        'page': Statistik(nama: _namaKar)
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(2))),
              SizedBox(width: 8),
              Text('Menu', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: textMain)),
            ],
          ),
        ),
        _menuRow(items.map((item) {
          return _buildMenuCard(
            item['icon'] as IconData,
            item['label'] as String,
            item['subtitle'] as String,
            item['color'] as Color,
            item['gradient'] as List<Color>,
            null,
            item['page'] as Widget,
          );
        }).toList()),
        SizedBox(height: 10),
        _menuRow([
          _buildMenuCard(
            Icons.system_update_alt_rounded,
            'Pembaruan',
            'Versi $appVersiTampil',
            Color(0xFF0EA5E9),
            [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
            null,
            null,
            onAction: _cekUpdate,
          ),
          if (_isApprover) ...[
            _buildMenuCard(
              Icons.checklist_rounded,
              'Approval Izin',
              _pendingIzin > 0 ? '$_pendingIzin pending' : 'Izin',
              Color(0xFF00B4D8),
              [Color(0xFF00B4D8), Color(0xFF33C8E5)],
              _pendingIzin,
              ApprovalIzinPage(karNik: _karNik, kdUnits: _kdUnits),
            ),
            _buildMenuCard(
              Icons.more_time_rounded,
              'Approval Lembur',
              _pendingLembur > 0 ? '$_pendingLembur pending' : 'Lembur',
              Color(0xFF0F766E),
              [Color(0xFF0F766E), Color(0xFF14B8A6)],
              _pendingLembur,
              ApprovalLemburPage(karNik: _karNik, kdUnits: _kdUnits),
            ),
          ],
        ]),
        if (_isPODMenu) ...[
          SizedBox(height: 10),
          _menuRow([
            _buildMenuCard(
              Icons.local_shipping_rounded,
              'Proof of Delivery',
              'Pengiriman',
              Color(0xFFF5A623),
              [Color(0xFFF5A623), Color(0xFFFFB84D)],
              null,
              PODPage(karNik: _karNik),
            ),
          ]),
        ],
      ],
    );
  }

  // Grid 4 kolom. Slot kosong menjaga lebar kartu tetap sama walau
  // jumlah menu dalam baris kurang dari empat.
  Widget _menuRow(List<Widget> cards) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(4, (i) {
          return Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: i < cards.length ? cards[i] : SizedBox(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenuCard(
    IconData icon, String label, String subtitle, Color color, List<Color> gradient,
    int? badge, Widget? page,
    {VoidCallback? onAction}) {
    // Skala mengikuti lebar layar supaya teks 4 kolom tetap terbaca di HP kecil
    // dan tidak membengkak di layar lebar.
    final skala = (MediaQuery.sizeOf(context).width / 400).clamp(0.85, 1.1).toDouble();
    final ukuranIkon = 36 * skala;
    final ukuranGlyph = (20 * skala).clamp(17.0, 22.0).toDouble();
    final ukuranLabel = (13 * skala).clamp(11.0, 14.0).toDouble();
    final ukuranSubtitle = (10 * skala).clamp(8.5, 11.0).toDouble();
    final paddingHorizontal = (12 * skala).clamp(9.0, 12.0).toDouble();
    final paddingAtas = (14 * skala).clamp(11.0, 14.0).toDouble();
    final paddingBawah = (12 * skala).clamp(9.0, 12.0).toDouble();
    final jarakIkon = (14 * skala).clamp(10.0, 14.0).toDouble();
    final badgeTinggi = (22 * skala).clamp(18.0, 22.0).toDouble();
    final badgeFont = (11 * skala).clamp(9.5, 11.0).toDouble();

    return GestureDetector(
      onTap: () {
        if (onAction != null) return onAction();
        if (page != null) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12, bottom: -16,
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: paddingHorizontal, right: paddingHorizontal, top: paddingAtas, bottom: paddingBawah),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: ukuranIkon, height: ukuranIkon,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: ukuranGlyph, color: Colors.white),
                  ),
                  SizedBox(height: jarakIkon),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: ukuranLabel, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: ukuranSubtitle, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  height: badgeTinggi,
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(badgeTinggi / 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Center(
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: GoogleFonts.inter(fontSize: badgeFont, fontWeight: FontWeight.w800, color: accentCoral),
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

