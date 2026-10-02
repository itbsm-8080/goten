import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:goten/services/izin_service.dart';

class ApprovalIzinPage extends StatefulWidget {
  final String? karNik;
  final List<String> kdUnits;
  const ApprovalIzinPage({super.key, this.karNik, this.kdUnits = const []});

  @override
  State<ApprovalIzinPage> createState() => _ApprovalIzinPageState();
}

class _ApprovalIzinPageState extends State<ApprovalIzinPage> {
  List<dynamic> _listIzin = [];
  bool _isLoading = true;
  bool _isApprover = false;
  String _kdUnit = '';
  List<String> _kdUnits = [];

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _statusFilter = 'PENDING';

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
    _cekRole();
  }

  Future<void> _cekRole() async {
    final response = await IzinService.cekRoleApproval(widget.karNik ?? '');
    if (mounted) {
      setState(() {
        _isApprover = response?['is_approver'] ?? false;
        _kdUnit = response?['kd_unit']?.toString() ?? '';
      });
      if (_isApprover) {
        _loadApproval();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadApproval() async {
    setState(() => _isLoading = true);
    try {
      final response = await IzinService.getApprovalList(
        kdUnits: widget.kdUnits, // pakai dari widget
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _listIzin = response?['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _proses(String ijNomor, String status) async {
    bool ok = await IzinService.prosesIzin(ijNomor, status);
    if (ok) {
      _showSnack(status == 'ACCEPT' ? 'Izin diterima ✅' : 'Izin ditolak ❌', false);
      _loadApproval();
    } else {
      _showSnack('Gagal memproses', true);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPT': return successGreen;
      case 'REJECT': return accentCoral;
      default: return warningOrange;
    }
  }

  void _showSnack(String msg, bool err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: err ? accentCoral : successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(16),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isApprover) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text('Approval Izin', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
          backgroundColor: surface,
          foregroundColor: textMain,
          elevation: 0,
          centerTitle: true,
          shape: Border(bottom: BorderSide(color: border)),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(color: accentCoral.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.lock, size: 48, color: accentCoral.withOpacity(0.4)),
            ),
            SizedBox(height: 16),
            Text('Tidak ada akses', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
            SizedBox(height: 4),
            Text('Hanya atasan unit yang dapat mengakses', style: GoogleFonts.inter(fontSize: 13, color: textLight)),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Approval Izin', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isDense: true,
                      items: ['ALL', 'PENDING', 'ACCEPT', 'REJECT'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (v) => setState(() => _statusFilter = v!),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Material(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _loadApproval,
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
                : _listIzin.isEmpty
                ? Center(child: Text('Tidak ada pengajuan', style: GoogleFonts.inter(fontSize: 14, color: textLight)))
                : ListView.builder(
              padding: EdgeInsets.all(14),
              itemCount: _listIzin.length,
              itemBuilder: (_, i) => _buildCard(_listIzin[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic izin) {
    Color stColor = _statusColor(izin['ij_status'] ?? 'PENDING');
    String tgl = izin['tanggal'] != null ? DateFormat('dd MMM yyyy – HH:mm').format(DateTime.parse(izin['tanggal'].toString())) : '';
    bool isPending = (izin['ij_status'] ?? 'PENDING') == 'PENDING';
    String fotoUrl = izin['ij_foto'] != null && izin['ij_foto'].toString().isNotEmpty
        ? 'http://103.103.22.7/cutikaryawan/bukti/${izin['ij_foto']}'
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama + Status
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.person, size: 20, color: primaryBlue),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(izin['kar_nama'] ?? 'Nama', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textMain)),
                    SizedBox(height: 2),
                    Text('${izin['nm_unit'] ?? ''} • $tgl', style: GoogleFonts.inter(fontSize: 11, color: textLight)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: stColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(izin['ij_status'] ?? 'PENDING', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: stColor)),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Alasan + Keterangan
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${izin['alasan'] ?? ''}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textMain)),
                if (izin['keterangan'] != null && izin['keterangan'].toString().isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(izin['keterangan'], style: GoogleFonts.inter(fontSize: 12, color: textSub)),
                ],
              ],
            ),
          ),
          // Foto preview
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
                  errorBuilder: (_, __, ___) => Container(height: 60, color: Colors.grey.shade200, child: Center(child: Text('Gagal memuat', style: GoogleFonts.inter(fontSize: 10, color: textLight)))),
                ),
              ),
            ),
          ],
          // Action buttons
          if (isPending) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _proses(izin['ij_nomor'], 'ACCEPT'),
                      style: ElevatedButton.styleFrom(backgroundColor: successGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 4),
                        Text('ACCEPT', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _proses(izin['ij_nomor'], 'REJECT'),
                      style: ElevatedButton.styleFrom(backgroundColor: accentCoral, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.close, size: 18),
                        SizedBox(width: 4),
                        Text('REJECT', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ],
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