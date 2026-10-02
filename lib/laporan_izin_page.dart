import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:goten/services/izin_service.dart';

class LaporanIzinPage extends StatefulWidget {
  final String? karNik;
  const LaporanIzinPage({super.key, this.karNik});

  @override
  State<LaporanIzinPage> createState() => _LaporanIzinPageState();
}

class _LaporanIzinPageState extends State<LaporanIzinPage> {
  List<dynamic> _listLaporan = [];
  bool _isLoading = true;

  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();

  static const Color bg = Color(0xFFF0F4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF1B1B2F);
  static const Color textSub = Color(0xFF5A5A7A);
  static const Color textLight = Color(0xFF9090A8);
  static const Color border = Color(0xFFE8ECF4);
  static const Color primaryBlue = Color(0xFF3B6DF0);
  static const Color successGreen = Color(0xFF00C897);
  static const Color accentCoral = Color(0xFFFF5E62);

  @override
  void initState() {
    super.initState();
    _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    setState(() => _isLoading = true);
    try {
      final response = await IzinService.getLaporanIzin(
        karNik: widget.karNik ?? '',
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      );
      if (mounted) {
        setState(() {
          _listLaporan = response?['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Laporan Izin', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
        backgroundColor: surface,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: surface, border: Border(bottom: BorderSide(color: border))),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? p = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (p != null) setState(() => _startDate = p);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                      child: Text(DateFormat('dd/MM/yy').format(_startDate), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textMain)),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('—', style: GoogleFonts.inter(color: textLight))),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? p = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (p != null) setState(() => _endDate = p);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                      child: Text(DateFormat('dd/MM/yy').format(_endDate), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textMain)),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Material(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _loadLaporan,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(padding: EdgeInsets.all(10), child: Icon(Icons.refresh_rounded, size: 20, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5))
                : _listLaporan.isEmpty
                ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(color: successGreen.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.folder_open_rounded, size: 48, color: successGreen.withOpacity(0.3)),
                ),
                SizedBox(height: 16),
                Text('Tidak ada laporan', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: textMain)),
                SizedBox(height: 4),
                Text('Izin yang disetujui akan muncul di sini', style: GoogleFonts.inter(fontSize: 12, color: textLight)),
              ]),
            )
                : ListView.builder(
              padding: EdgeInsets.all(14),
              itemCount: _listLaporan.length,
              itemBuilder: (_, i) => _buildCard(_listLaporan[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic laporan) {
    String tgl = laporan['tanggal'] != null
        ? DateFormat('dd MMM yyyy – HH:mm').format(DateTime.parse(laporan['tanggal'].toString()))
        : '';
    String fotoUrl = laporan['ij_foto'] != null && laporan['ij_foto'].toString().isNotEmpty
        ? 'http://103.103.22.7/cutikaryawan/bukti/${laporan['ij_foto']}'
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Alasan + Tanggal
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle_rounded, size: 20, color: successGreen),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(laporan['alasan'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textMain)),
                    SizedBox(height: 2),
                    Text(tgl, style: GoogleFonts.inter(fontSize: 11, color: textLight)),
                  ],
                ),
              ),
            ],
          ),
          // Keterangan
          if (laporan['keterangan'] != null && laporan['keterangan'].toString().isNotEmpty) ...[
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(laporan['keterangan'], style: GoogleFonts.inter(fontSize: 12, color: textSub)),
            ),
          ],
          // Foto
          if (fotoUrl.isNotEmpty) ...[
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showFullImage(fotoUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  fotoUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 80,
                      color: Colors.grey.shade100,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    color: Colors.grey.shade100,
                    child: Center(child: Icon(Icons.broken_image, size: 24, color: textLight)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}