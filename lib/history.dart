import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:goten/absen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'utils/device_utils.dart';
import 'dart:io' show Platform;
import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;
import 'package:goten/dashboard.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:goten/model/history_absen.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/karyawan_service.dart';
import 'services/absensi_service.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> with TickerProviderStateMixin {
  final TextStyle whiteText = TextStyle(color: Colors.white);
  List<HistoryAbsensi> _listAbsensi = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _ambilAbsensi();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _ambilAbsensi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? deviceId = await DeviceUtils.getDeviceId();
      if (deviceId == null) return;

      final karyawanData = await KaryawanService.getKaryawanByDevice(deviceId);
      if (karyawanData == null || karyawanData['kar_nama'] == null) return;

      final historyData = await AbsensiService.getHistoryAbsensi(karyawanData['kar_nama']);

      if (mounted) {
        setState(() {
          _listAbsensi = historyData;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading absensi history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildEnhancedHeader(),

          // Stats summary card
          _buildStatsCard(),

          // Section header
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Riwayat 10 Hari Terakhir",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _listAbsensi.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(),
          )
        ],
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
          Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  "Riwayat Absensi",
                  style: whiteText.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Pantau kehadiran Anda",
                  style: whiteText.copyWith(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    int hadir = _listAbsensi.where((a) => a.historyAbsensiIn != null).length;
    int tepat = _listAbsensi.where((a) => a.status == 'Tepat Waktu').length;
    int terlambat = _listAbsensi.where((a) => a.status == 'Terlambat').length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ringkasan Kehadiran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', _listAbsensi.length, Icons.calendar_today, Colors.white),
              _buildStatItem('Hadir', hadir, Icons.check_circle, Colors.green.shade200),
              _buildStatItem('Tepat', tepat, Icons.schedule, Colors.blue.shade200),
              _buildStatItem('Terlambat', terlambat, Icons.warning, Colors.orange.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat riwayat absensi...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
                Icons.history_outlined,
                size: 64,
                color: Colors.grey.shade400
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Belum ada riwayat absensi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Lakukan absensi pertama Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _ambilAbsensi,
        color: Colors.blue.shade600,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: _listAbsensi.length,
          itemBuilder: (context, index) {
            HistoryAbsensi absensi = _listAbsensi[index];
            DateTime tanggal = DateFormat('yyyy-MM-dd').parse(absensi.tanggal);
            String tanggalFinal = DateFormat.yMMMMEEEEd('id').format(tanggal).toString();

            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              margin: EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with date
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.blue.shade600,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tanggalFinal,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(tanggal),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(absensi.status),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Attendance times
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeCard(
                              'Check In',
                              absensi.historyAbsensiIn?.toString() == 'null' || absensi.historyAbsensiIn == null
                                  ? null
                                  : absensi.historyAbsensiIn.toString(),
                              Icons.login,
                              Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeCard(
                              'Check Out',
                              absensi.out?.toString() == 'null' || absensi.out == null
                                  ? null
                                  : absensi.out.toString(),
                              Icons.logout,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, String? time, IconData icon, Color color) {
    bool hasTime = time != null;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasTime ? color.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasTime ? color.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasTime ? Icons.check_circle : icon,
            color: hasTime ? color : Colors.grey.shade400,
            size: 20,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            hasTime ? time! : 'Belum',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: hasTime ? color : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor = status == 'Tepat Waktu' ? Colors.green : Colors.orange;
    Color textColor = Colors.white;
    IconData icon = status == 'Tepat Waktu' ? Icons.check_circle : Icons.schedule;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Hari ini';
    if (difference == 1) return 'Kemarin';
    if (difference < 7) return '$difference hari yang lalu';
    return '${(difference / 7).floor()} minggu yang lalu';
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }
}