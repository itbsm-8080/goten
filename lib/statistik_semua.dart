import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

class StatistikSemua extends StatefulWidget {
  final String? nama;
  const StatistikSemua({super.key, this.nama});

  @override
  State<StatistikSemua> createState() => _StatistikSemuaState();
}

class _StatistikSemuaState extends State<StatistikSemua> {
  int _touchedIndex = -1;
  double _tepat = 0;
  double _terlambat = 0;
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
  static const Color purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://188.166.226.122:8080/statistik/all'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"nama": widget.nama ?? ''},
      );
      final data = jsonDecode(response.body);
      setState(() {
        _tepat = pick(data, 'data', 0, 'PersentaseTepatWaktu').asDoubleOrNull() ?? 0;
        _terlambat = pick(data, 'data', 0, 'PersentaseTerlambat').asDoubleOrNull() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Statistik Keseluruhan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
        backgroundColor: surface,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 4, height: 18,
                      decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(2)),
                    ),
                    SizedBox(width: 8),
                    Text('Persentase Keseluruhan', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: textMain)),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 240,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 55,
                      sections: [
                        PieChartSectionData(
                          color: successGreen,
                          value: _tepat,
                          title: '${_tepat.toStringAsFixed(1)}%',
                          radius: _touchedIndex == 0 ? 75 : 65,
                          titleStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: accentCoral,
                          value: _terlambat,
                          title: '${_terlambat.toStringAsFixed(1)}%',
                          radius: _touchedIndex == 1 ? 75 : 65,
                          titleStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(successGreen, 'Tepat Waktu', '${_tepat.toStringAsFixed(1)}%'),
                    SizedBox(width: 32),
                    _legendDot(accentCoral, 'Terlambat', '${_terlambat.toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textSub)),
            Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: textMain)),
          ],
        ),
      ],
    );
  }
}