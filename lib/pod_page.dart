import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:goten/services/pod_service.dart';
import 'package:goten/config/app_config.dart';

class PODPage extends StatefulWidget {
  final String? karNik;
  const PODPage({super.key, this.karNik});

  @override
  State<PODPage> createState() => _PODPageState();
}

class _PODPageState extends State<PODPage> {
  List<dynamic> _list = [];
  bool _isLoading = true;
  int _tab = 0; // 0 = Belum, 1 = Selesai
  final TextEditingController _searchDoCtrl = TextEditingController();

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
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
  static const Color warningOrange = Color(0xFFFF8C42);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDoCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredList {
    if (_tab != 0 || _searchDoCtrl.text.trim().isEmpty) return _list;
    final q = _searchDoCtrl.text.trim().toLowerCase();
    return _list.where((item) {
      final doNomor = (item['do_nomor'] ?? '').toString().toLowerCase();
      final cusNama = (item['Cus_nama'] ?? '').toString().toLowerCase();
      final faktur = (item['faktur'] ?? '').toString().toLowerCase();
      return doNomor.contains(q) || cusNama.contains(q) || faktur.contains(q);
    }).toList();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? response;
      if (_tab == 0) {
        response = await PodService.getListBelum(karNik: widget.karNik ?? '');
      } else {
        response = await PodService.getListPOD(
          karNik: widget.karNik ?? '',
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        );
      }
      if (mounted) {
        setState(() {
          _list = response?['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _datePart(dynamic val) {
    if (val == null) return '';
    final s = val.toString();
    final dt = DateTime.tryParse(s);
    if (dt != null) {
      return DateFormat('yyyy-MM-dd').format(dt);
    }
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  String _formatTgl(dynamic val) {
    final s = _datePart(val);
    if (s.isEmpty) return '';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  bool _isToday(dynamic val) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _datePart(val) == today;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Proof of Delivery', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
        backgroundColor: surface,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PODFormPage(karNik: widget.karNik))).then((_) => _load()),
        backgroundColor: primaryBlue,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildTabFilter(),
          if (_tab == 0) _buildBelumSearch(),
          if (_tab == 1) _buildFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5))
                : _filteredList.isEmpty
                ? Center(child: Text(_tab == 0 ? 'Semua DO sudah dibuatkan POD' : 'Tidak ada transaksi', style: GoogleFonts.inter(fontSize: 14, color: textLight)))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: primaryBlue,
                    child: ListView.builder(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
                      itemCount: _filteredList.length,
                      itemBuilder: (_, i) => _tab == 0 ? _buildBelumCard(_filteredList[i]) : _buildCard(_filteredList[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
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
              onTap: _load,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabFilter() {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        children: [
          Expanded(child: _buildTabPill('Belum Selesai', 0, Icons.pending_actions)),
          Expanded(child: _buildTabPill('Selesai', 1, Icons.check_circle_outline)),
        ],
      ),
    );
  }

  Widget _buildTabPill(String label, int tab, IconData icon) {
    final bool active = _tab == tab;
    return GestureDetector(
      onTap: () {
        if (_tab == tab) return;
        setState(() => _tab = tab);
        _load();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? primaryBlue : textLight),
            SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: active ? primaryBlue : textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildBelumSearch() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: TextField(
        controller: _searchDoCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari nomor DO / faktur / customer...',
          prefixIcon: Icon(Icons.search, size: 18, color: textLight),
          filled: true,
          fillColor: surface,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryBlue)),
        ),
        style: GoogleFonts.inter(fontSize: 13),
      ),
    );
  }

  Widget _buildBelumCard(dynamic item) {
    final String doNomor = (item['do_nomor'] ?? '').toString();
    final String cusNama = (item['Cus_nama'] ?? '').toString();
    final String faktur = (item['faktur'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PODFormPage(
          karNik: widget.karNik,
          initialDo: {
            'Nomor': item['do_nomor'],
            'Tanggal': item['do_tanggal'],
            'Customer': item['Cus_nama'],
            'Alamat': item['Cus_alamat'],
            'Cus_kode': item['do_cus_Kode'],
          },
        ))).then((_) => _load());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: warningOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.local_shipping_rounded, size: 17, color: warningOrange),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(doNomor, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if ((item['do_tanggal'] ?? '').toString().isNotEmpty) ...[
                        SizedBox(width: 6),
                        Text(_formatTgl(item['do_tanggal']), style: GoogleFonts.inter(fontSize: 10, color: textLight)),
                      ],
                    ],
                  ),
                  if (cusNama.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 12, color: textLight),
                        SizedBox(width: 4),
                        Expanded(child: Text(cusNama, style: GoogleFonts.inter(fontSize: 10, color: textSub), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                  if (faktur.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.receipt_outlined, size: 12, color: textLight),
                        SizedBox(width: 4),
                        Expanded(child: Text('Faktur: $faktur', style: GoogleFonts.inter(fontSize: 10, color: textLight), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(dynamic item) {
    final bool editable = _isToday(item['pod_tanggal']);
    final String doNomor = (item['pod_do_nomor'] ?? '').toString();
    final String cusNama = (item['Cus_nama'] ?? '').toString();
    final bool hasFoto = (item['pod_foto'] ?? '').toString().isNotEmpty;
    final String tgl = _formatTgl(item['pod_tanggal']);

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.local_shipping_rounded, size: 17, color: primaryBlue),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item['pod_nomor'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (tgl.isNotEmpty) ...[
                      SizedBox(width: 6),
                      Text(tgl, style: GoogleFonts.inter(fontSize: 10, color: textLight)),
                    ],
                  ],
                ),
                if (doNomor.isNotEmpty || cusNama.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Row(
                    children: [
                      if (doNomor.isNotEmpty) ...[
                        Icon(Icons.local_shipping_rounded, size: 12, color: textLight),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(doNomor, style: GoogleFonts.inter(fontSize: 10, color: textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (cusNama.isNotEmpty) SizedBox(width: 8),
                      ],
                      if (cusNama.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 12, color: textLight),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(cusNama, style: GoogleFonts.inter(fontSize: 10, color: textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (editable)
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'foto':
                    _showFotoPreview(item);
                    break;
                  case 'edit':
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PODFormPage(karNik: widget.karNik, editData: item))).then((_) => _load());
                    break;
                  case 'hapus':
                    _confirmHapus(item);
                    break;
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: surface,
              itemBuilder: (_) => [
                if (hasFoto)
                  PopupMenuItem(value: 'foto', child: Row(children: [
                    Icon(Icons.visibility, size: 16, color: primaryBlue),
                    SizedBox(width: 8),
                    Text('Lihat Foto', style: GoogleFonts.inter(fontSize: 13, color: textMain)),
                  ])),
                PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit, size: 16, color: primaryBlue),
                  SizedBox(width: 8),
                  Text('Edit', style: GoogleFonts.inter(fontSize: 13, color: textMain)),
                ])),
                PopupMenuItem(value: 'hapus', child: Row(children: [
                  Icon(Icons.delete, size: 16, color: accentCoral),
                  SizedBox(width: 8),
                  Text('Hapus', style: GoogleFonts.inter(fontSize: 13, color: accentCoral)),
                ])),
              ],
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.more_vert, size: 16, color: primaryBlue),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmHapus(dynamic item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus POD', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
        content: Text('Yakin hapus ${item['pod_nomor']}?', style: GoogleFonts.inter(fontSize: 14, color: textSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: GoogleFonts.inter(color: textLight))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Hapus', style: GoogleFonts.inter(color: accentCoral, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      final res = await PodService.hapusPOD(
        karNik: widget.karNik ?? '',
        podNomor: item['pod_nomor'].toString(),
      );
      if (!mounted) return;
      if (res) {
        _showSnack('POD dihapus', false);
        _load();
      } else {
        _showSnack('Gagal hapus', true);
      }
    }
  }

  void _showFotoPreview(dynamic item) {
    final url = '${AppConfig.buktiBaseUrl}/${item['pod_foto']}';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 400,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 28, color: Colors.white54),
                        SizedBox(height: 6),
                        Text('Gagal memuat foto', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}

// ==================== FORM TAMBAH/EDIT ====================
class PODFormPage extends StatefulWidget {
  final String? karNik;
  final dynamic editData;
  final Map<String, dynamic>? initialDo;
  const PODFormPage({super.key, this.karNik, this.editData, this.initialDo});

  @override
  State<PODFormPage> createState() => _PODFormPageState();
}

class _PODFormPageState extends State<PODFormPage> {
  Map<String, dynamic>? _selectedDo;
  DateTime _selectedDate = DateTime.now();
  File? _selectedFile;
  String? _existingFoto;
  bool _isSubmitting = false;
  bool _removeExistingFoto = false;

  bool get isEdit => widget.editData != null;

  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF1B1B2F);
  static const Color textSub = Color(0xFF5A5A7A);
  static const Color textLight = Color(0xFF9090A8);
  static const Color border = Color(0xFFE8ECF4);
  static const Color primaryBlue = Color(0xFF3B6DF0);
  static const Color bg = Color(0xFFF0F4FF);
  static const Color successGreen = Color(0xFF00C897);
  static const Color accentCoral = Color(0xFFFF5E62);

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final data = widget.editData;
      final tglStr = data['pod_tanggal']?.toString() ?? '';
      _selectedDo = {
        'Nomor': data['pod_do_nomor'],
        'Customer': data['Cus_nama'],
        'Alamat': data['Cus_alamat'],
        'Cus_kode': data['pod_cus_kode'],
      };
      final dtParsed = DateTime.tryParse(tglStr);
      if (dtParsed != null) {
        _selectedDate = dtParsed;
      } else {
        _selectedDate = DateTime.tryParse(tglStr.length >= 10 ? tglStr.substring(0, 10) : tglStr) ?? DateTime.now();
      }
      _existingFoto = data['pod_foto']?.toString();
    } else if (widget.initialDo != null) {
      _selectedDo = {
        'Nomor': widget.initialDo!['Nomor'],
        'Tanggal': widget.initialDo!['Tanggal'],
        'Customer': widget.initialDo!['Customer'],
        'Alamat': widget.initialDo!['Alamat'],
        'Cus_kode': widget.initialDo!['Cus_kode'],
      };
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _fotoUrl => '${AppConfig.buktiBaseUrl}/$_existingFoto';

  Future<void> _pickDo() async {
    final selected = await _showCariDoDialog();
    if (selected != null) {
      setState(() => _selectedDo = selected);
    }
  }

  Future<Map<String, dynamic>?> _showCariDoDialog() async {
    List<dynamic> listDo = [];
    bool loading = true;
    bool didInitialLoad = false;
    final searchCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (!didInitialLoad) {
            didInitialLoad = true;
            Future.microtask(() async {
              final r = await PodService.cariDO(karNik: widget.karNik ?? '');
              if (!ctx.mounted) return;
              setDialogState(() {
                listDo = r?['data'] ?? [];
                loading = false;
              });
            });
          }
          return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: 480,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cari DO', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
                SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor DO / faktur / customer...',
                    prefixIcon: Icon(Icons.search, size: 18, color: textLight),
                    filled: true,
                    fillColor: bg,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryBlue)),
                  ),
                  style: GoogleFonts.inter(fontSize: 13),
                  onSubmitted: (v) async {
                    setDialogState(() => loading = true);
                    final r = await PodService.cariDO(karNik: widget.karNik ?? '', keyword: v);
                    setDialogState(() { listDo = r?['data'] ?? []; loading = false; });
                  },
                ),
                SizedBox(height: 12),
                Expanded(
                  child: loading
                      ? Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5))
                      : listDo.isEmpty
                      ? Center(child: Text('Tidak ada DO tersedia', style: GoogleFonts.inter(fontSize: 13, color: textLight)))
                      : ListView.builder(
                          itemCount: listDo.length,
                          itemBuilder: (_, i) {
                            final item = listDo[i];
                            return InkWell(
                              onTap: () => Navigator.pop(ctx, {
                                'Nomor': item['Nomor'],
                                'Tanggal': item['Tanggal'],
                                'Customer': item['Customer'],
                                'Alamat': item['Alamat'],
                                'Cus_kode': item['Cus_kode'],
                              }),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.local_shipping_rounded, size: 18, color: primaryBlue),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['Nomor']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textMain)),
                                          SizedBox(height: 2),
                                          Text(item['Customer']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, color: textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          if ((item['Faktur'] ?? '').toString().isNotEmpty) ...[
                                            SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.receipt_outlined, size: 12, color: textLight),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(item['Faktur'].toString(), style: GoogleFonts.inter(fontSize: 10, color: textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, size: 18, color: textLight),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedDo == null) {
      _showSnack('Pilih DO terlebih dahulu', true);
      return;
    }
    if (_selectedFile == null && (!isEdit || (_existingFoto == null || _existingFoto!.isEmpty || _removeExistingFoto))) {
      _showSnack('Upload foto wajib diisi', true);
      return;
    }

    setState(() => _isSubmitting = true);

    String tanggalStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String? uploadedFileName;

    if (_selectedFile != null) {
      try {
        var request = http.MultipartRequest('POST', Uri.parse(AppConfig.uploadFotoEndpoint));
        request.fields['prefix'] = 'POD';
        request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

        var streamedResponse = await request.send();
        var responseBody = await streamedResponse.stream.bytesToString();
        print('Upload response: $responseBody');

        var respJson = jsonDecode(responseBody);
        if (respJson['status'] == 'success') {
          uploadedFileName = respJson['filename'];
        } else {
          _showSnack('Upload gagal: ${respJson['message'] ?? 'Unknown error'}', true);
          setState(() => _isSubmitting = false);
          return;
        }
      } catch (e) {
        print('Upload error: $e');
        _showSnack('Upload foto error: $e', true);
        setState(() => _isSubmitting = false);
        return;
      }
    }

    String? finalFoto;
    if (_removeExistingFoto) {
      finalFoto = null;
    } else if (uploadedFileName != null) {
      finalFoto = uploadedFileName;
    } else {
      finalFoto = _existingFoto;
    }

    bool ok;
    if (isEdit) {
      ok = await PodService.editPOD(
        karNik: widget.karNik ?? '',
        podNomor: widget.editData['pod_nomor'].toString(),
        podTanggal: tanggalStr,
        podFoto: finalFoto,
      );
    } else {
      ok = await PodService.tambahPOD(
        karNik: widget.karNik ?? '',
        podDoNomor: _selectedDo!['Nomor'].toString(),
        podTanggal: tanggalStr,
        podFoto: finalFoto!,
        podCusKode: _selectedDo!['Cus_kode'].toString(),
      );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      _showSnack(isEdit ? 'POD diperbarui!' : 'POD disimpan!', false);
      Navigator.pop(context, true);
    } else {
      _showSnack('Gagal menyimpan', true);
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

  Future<void> _pickFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
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
              child: Text('Ambil Foto', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
            ),
            SizedBox(height: 4),
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.photo_camera, size: 18, color: primaryBlue),
              ),
              title: Text('Kamera', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textMain)),
              trailing: Icon(Icons.chevron_right, size: 18, color: textLight),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.photo_library, size: 18, color: successGreen),
              ),
              title: Text('Galeri', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textMain)),
              trailing: Icon(Icons.chevron_right, size: 18, color: textLight),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1920, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() {
          _selectedFile = File(picked.path);
          _removeExistingFoto = false;
        });
      }
    } catch (e) {
      print('Gambar error: $e');
      _showSnack('Gagal mengambil foto', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit POD' : 'POD Baru',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain),
        ),
        backgroundColor: surface,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DO (cari / readonly saat edit)
            _buildLabel('DO'),
            SizedBox(height: 8),
            if (isEdit)
              _buildInputRow(
                icon: Icons.local_shipping_rounded,
                text: _selectedDo?['Nomor']?.toString() ?? '',
                isSelected: true,
              )
            else
              GestureDetector(
                onTap: _pickDo,
                child: _buildInputRow(
                  icon: Icons.search,
                  text: _selectedDo != null ? _selectedDo!['Nomor'].toString() : 'Cari DO',
                  isSelected: _selectedDo != null,
                ),
              ),
            SizedBox(height: 16),

            // Customer (auto)
            _buildLabel('Customer'),
            SizedBox(height: 8),
            _buildInputRow(
              icon: Icons.person_outline,
              text: (_selectedDo?['Customer']?.toString() ?? '').isEmpty
                  ? (isEdit ? '' : 'Otomatis terisi dari DO')
                  : _selectedDo!['Customer'].toString(),
              isSelected: (_selectedDo?['Customer']?.toString() ?? '').isNotEmpty,
            ),
            SizedBox(height: 16),

            // Alamat (auto)
            _buildLabel('Alamat'),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 16, color: (_selectedDo?['Alamat']?.toString() ?? '').isNotEmpty ? primaryBlue : textLight),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (_selectedDo?['Alamat']?.toString() ?? '').isEmpty
                          ? (isEdit ? '' : 'Otomatis terisi dari DO')
                          : _selectedDo!['Alamat'].toString(),
                      style: GoogleFonts.inter(fontSize: 14, color: (_selectedDo?['Alamat']?.toString() ?? '').isNotEmpty ? textMain : textLight),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Tanggal
            _buildLabel('Tanggal'),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                DateTime? p = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (p != null) setState(() => _selectedDate = p);
              },
              child: _buildInputRow(
                icon: Icons.calendar_today,
                text: DateFormat('dd MMMM yyyy').format(_selectedDate),
                isSelected: true,
              ),
            ),
            SizedBox(height: 16),

            // Upload Foto
            _buildLabel('Upload Foto'),
            SizedBox(height: 8),

            if (isEdit && _existingFoto != null && _existingFoto!.isNotEmpty && !_removeExistingFoto) ...[
              _buildExistingFoto(),
              SizedBox(height: 8),
            ],

            if (_selectedFile != null) ...[
              _buildPreviewNewFoto(),
              SizedBox(height: 8),
            ],

            if (_selectedFile != null) ...[
              _buildFileNameInfo(),
              SizedBox(height: 8),
            ],

            Material(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _pickFoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate, size: 18, color: primaryBlue),
                      SizedBox(width: 10),
                      Text(
                        _selectedFile != null ? 'Ganti foto' : (_existingFoto != null ? 'Ganti foto' : 'Pilih foto'),
                        style: GoogleFonts.inter(fontSize: 13, color: textLight),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textMain));
  }

  Widget _buildInputRow({required IconData icon, required String text, required bool isSelected}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? primaryBlue : textLight),
          SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: isSelected ? textMain : textLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingFoto() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Foto tersimpan', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: successGreen)),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => setState(() => _removeExistingFoto = true),
                child: Icon(Icons.close, size: 18, color: accentCoral),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _fotoUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: primaryBlue,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                color: Colors.grey.shade100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 24, color: textLight),
                      SizedBox(height: 4),
                      Text('Gagal memuat', style: GoogleFonts.inter(fontSize: 10, color: textLight)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 6),
          Text(_existingFoto!, style: GoogleFonts.inter(fontSize: 11, color: textLight)),
        ],
      ),
    );
  }

  Widget _buildPreviewNewFoto() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('Foto baru', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: primaryBlue)),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedFile!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileNameInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, size: 14, color: textLight),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedFile!.path.split('/').last,
              style: GoogleFonts.inter(fontSize: 11, color: textSub),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
