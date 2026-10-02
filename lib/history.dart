import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:goten/model/history_absen.dart';
import 'package:goten/services/absensi_service.dart';
import 'package:goten/services/karyawan_service.dart';
import 'package:goten/utils/device_utils.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<HistoryAbsensi> _listAbsensi = [];
  bool _isLoading = true;

  static const Color bg = Color(0xFFF0F4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF1B1B2F);
  static const Color textSub = Color(0xFF5A5A7A);
  static const Color textLight = Color(0xFF9090A8);
  static const Color border = Color(0xFFE8ECF4);
  static const Color primaryBlue = Color(0xFF3B6DF0);
  static const Color successGreen = Color(0xFF00C897);
  static const Color accentCoral = Color(0xFFFF5E62);
  static const Color warningOrange = Color(0xFFFF8C42);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      String? deviceId = await DeviceUtils.getDeviceId();
      if (deviceId == null) return;
      final karyawanData = await KaryawanService.getKaryawanByDevice(deviceId);
      if (karyawanData == null || karyawanData['kar_nama'] == null) return;
      final historyData = await AbsensiService.getHistoryAbsensi(karyawanData['kar_nama']);
      if (mounted) setState(() { _listAbsensi = historyData; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Riwayat', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
        backgroundColor: surface,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5))
          : _listAbsensi.isEmpty
          ? _empty()
          : RefreshIndicator(
        onRefresh: _loadHistory,
        color: primaryBlue,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _listAbsensi.length,
          itemBuilder: (_, i) => _card(_listAbsensi[i]),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.receipt_long_rounded, size: 48, color: primaryBlue.withOpacity(0.3)),
        ),
        SizedBox(height: 16),
        Text('Belum ada riwayat', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: textMain)),
        SizedBox(height: 4),
        Text('Lakukan absensi terlebih dahulu', style: GoogleFonts.inter(fontSize: 12, color: textLight)),
      ]),
    );
  }

  Widget _card(HistoryAbsensi a) {
    DateTime tgl = DateFormat('yyyy-MM-dd').parse(a.tanggal);
    String hari = DateFormat('EEEE', 'id').format(tgl);
    String tanggalStr = DateFormat('dd MMM yyyy', 'id').format(tgl);
    bool tepat = a.status == 'Tepat Waktu';
    bool hasIn = a.historyAbsensiIn != null && a.historyAbsensiIn.toString() != 'null';
    bool hasOut = a.out != null && a.out.toString() != 'null';
    String inTime = hasIn ? (a.historyAbsensiIn.toString().contains(' ') ? a.historyAbsensiIn.toString().split(' ').last : a.historyAbsensiIn.toString()) : '—';
    String outTime = hasOut ? (a.out.toString().contains(' ') ? a.out.toString().split(' ').last : a.out.toString()) : '—';
    Color stColor = tepat ? successGreen : warningOrange;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: stColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tepat ? Icons.check_circle_rounded : Icons.schedule_rounded, size: 20, color: stColor),
          ),
          SizedBox(width: 12),
          // Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hari, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textMain)),
                SizedBox(height: 2),
                Text(tanggalStr, style: GoogleFonts.inter(fontSize: 11, color: textLight)),
              ],
            ),
          ),
          // In
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: successGreen.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.login, size: 12, color: successGreen),
              SizedBox(width: 4),
              Text(inTime, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: hasIn ? successGreen : textLight)),
            ]),
          ),
          SizedBox(width: 8),
          // Out
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: accentCoral.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.logout, size: 12, color: accentCoral),
              SizedBox(width: 4),
              Text(outTime, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: hasOut ? accentCoral : textLight)),
            ]),
          ),
        ],
      ),
    );
  }
}