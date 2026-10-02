import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:goten/services/izin_service.dart';
import 'package:goten/config/app_config.dart';

class IzinPage extends StatefulWidget {
  final String? karNik;
  const IzinPage({super.key, this.karNik});

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  List<dynamic> _listIzin = [];
  bool _isLoading = true;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _statusFilter = 'ALL';

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
    _loadIzin();
  }

  Future<void> _loadIzin() async {
    setState(() => _isLoading = true);
    try {
      final response = await IzinService.getListIzin(
        karNik: widget.karNik ?? '',
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

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPT': return successGreen;
      case 'REJECT': return accentCoral;
      default: return warningOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Pengajuan Izin', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
        backgroundColor: surface,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TambahIzinPage(karNik: widget.karNik))).then((_) => _loadIzin()),
        backgroundColor: primaryBlue,
        child: Icon(Icons.add, color: Colors.white),
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
                // Tombol Load
                Material(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _loadIzin,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                    ),
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

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: stColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.edit_calendar, size: 20, color: stColor),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(izin['alasan'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textMain)),
                SizedBox(height: 2),
                Text(tgl, style: GoogleFonts.inter(fontSize: 11, color: textLight)),
                if (izin['keterangan'] != null && izin['keterangan'].toString().isNotEmpty)
                  Text(izin['keterangan'], style: GoogleFonts.inter(fontSize: 11, color: textSub)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: stColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(izin['ij_status'] ?? 'PENDING', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: stColor)),
          ),
          if (isPending) ...[
            SizedBox(width: 6),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TambahIzinPage(karNik: widget.karNik, editData: izin))).then((_) => _loadIzin()),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.edit, size: 16, color: primaryBlue),
              ),
            ),
            SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                bool ok = await IzinService.hapusIzin(izin['ij_nomor']);
                if (ok) { _showSnack('Izin dihapus', false); _loadIzin(); }
                else { _showSnack('Gagal hapus', true); }
              },
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(color: accentCoral.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.delete, size: 16, color: accentCoral),
              ),
            ),
          ],
        ],
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

// ==================== FORM TAMBAH/EDIT (BEDA HALAMAN) ====================
class TambahIzinPage extends StatefulWidget {
  final String? karNik;
  final dynamic editData;
  const TambahIzinPage({super.key, this.karNik, this.editData});

  @override
  State<TambahIzinPage> createState() => _TambahIzinPageState();
}

class _TambahIzinPageState extends State<TambahIzinPage> {
  DateTime? _selectedDate;
  String _alasan = 'Sakit';
  TextEditingController _ketCtrl = TextEditingController();
  File? _selectedFile;
  String? _existingFoto; // foto yang sudah ada (edit mode)
  String? _previewPath; // path untuk preview
  bool _isSubmitting = false;
  bool _removeExistingFoto = false;

  bool get isEdit => widget.editData != null;

  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF1B1B2F);
  static const Color textLight = Color(0xFF9090A8);
  static const Color border = Color(0xFFE8ECF4);
  static const Color primaryBlue = Color(0xFF3B6DF0);
  static const Color bg = Color(0xFFF0F4FF);
  static const Color successGreen = Color(0xFF00C897);
  static const Color accentCoral = Color(0xFFFF5E62);
  static const Color textSub = Color(0xFF5A5A7A);

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final data = widget.editData;
      setState(() {
        _selectedDate = DateTime.tryParse(data['tanggal']?.toString() ?? '');
        _alasan = data['alasan'] ?? 'Sakit';
        _ketCtrl.text = data['keterangan'] ?? '';
        _existingFoto = data['ij_foto']?.toString();
      });
    }
  }

  @override
  void dispose() {
    _ketCtrl.dispose();
    super.dispose();
  }

  String get _fotoUrl {
    if (_existingFoto == null || _existingFoto!.isEmpty) return '';
    // Pakai IP langsung seperti Delphi
    return 'http://103.103.22.7/cutikaryawan/bukti/$_existingFoto';
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      _showSnack('Pilih tanggal', true);
      return;
    }

    setState(() => _isSubmitting = true);

    String tanggalStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDate!);
    String? uploadedFileName;

    // Upload foto baru jika ada
    if (_selectedFile != null) {
      try {
        // URL UPLOAD — pakai IP langsung seperti Delphi
        const String uploadUrl = 'http://103.103.22.7/cutikaryawan/upload.php';

        var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
        request.fields['prefix'] = 'IZ'; // prefix seperti di Delphi
        request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

        var streamedResponse = await request.send();
        var responseBody = await streamedResponse.stream.bytesToString();

        print('Upload response: $responseBody'); // debug

        var respJson = jsonDecode(responseBody);

        if (respJson['status'] == 'success') {
          uploadedFileName = respJson['filename'];
          print('Uploaded: $uploadedFileName');
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

    // Tentukan foto final
    String? finalFoto;
    if (_removeExistingFoto) {
      finalFoto = null;
    } else if (uploadedFileName != null) {
      finalFoto = uploadedFileName;
    } else {
      finalFoto = _existingFoto;
    }

    print('Final foto: $finalFoto'); // debug

    bool ok;
    if (isEdit) {
      ok = await IzinService.editIzin(
        ijNomor: widget.editData['ij_nomor'],
        tanggal: tanggalStr,
        alasan: _alasan,
        keterangan: _ketCtrl.text,
        foto: finalFoto,
      );
    } else {
      ok = await IzinService.tambahIzin(
        karNik: widget.karNik ?? '',
        tanggal: tanggalStr,
        alasan: _alasan,
        keterangan: _ketCtrl.text,
        foto: finalFoto,
      );
    }

    setState(() => _isSubmitting = false);

    if (ok) {
      _showSnack(isEdit ? 'Izin diperbarui!' : 'Izin diajukan!', false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Izin' : 'Pengajuan Izin Baru',
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
            // Tanggal
            _buildLabel('Tanggal'),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                DateTime? p = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (p != null) setState(() => _selectedDate = p);
              },
              child: _buildInputRow(
                icon: Icons.calendar_today,
                text: _selectedDate != null ? DateFormat('dd MMMM yyyy').format(_selectedDate!) : 'Pilih Tanggal',
                isSelected: _selectedDate != null,
              ),
            ),
            SizedBox(height: 16),

            // Alasan
            _buildLabel('Alasan'),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _alasan,
                  isExpanded: true,
                  items: ['Sakit', 'Cuti Tahunan', 'Setengah Hari']
                      .map((a) => DropdownMenuItem(value: a, child: Text(a, style: GoogleFonts.inter(fontSize: 14))))
                      .toList(),
                  onChanged: (v) => setState(() => _alasan = v!),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Keterangan
            _buildLabel('Keterangan'),
            SizedBox(height: 8),
            TextField(
              controller: _ketCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis keterangan...',
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue)),
                contentPadding: EdgeInsets.all(14),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            SizedBox(height: 16),

            // Upload Foto
            _buildLabel('Upload Foto'),
            SizedBox(height: 8),

            // Existing foto (edit mode)
            if (isEdit && _existingFoto != null && _existingFoto!.isNotEmpty && !_removeExistingFoto) ...[
              _buildExistingFoto(),
              SizedBox(height: 8),
            ],

            // Preview foto baru yang dipilih
            if (_selectedFile != null) ...[
              _buildPreviewNewFoto(),
              SizedBox(height: 8),
            ],

            // Nama file info
            if (_selectedFile != null) ...[
              _buildFileNameInfo(),
              SizedBox(height: 8),
            ],

            // Tombol pilih foto
            Material(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    setState(() {
                      _selectedFile = File(result.files.single.path!);
                      _removeExistingFoto = false;
                    });
                  }
                },
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

            // Submit
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
                  isEdit ? 'Simpan Perubahan' : 'Ajukan Izin',
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
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: isSelected ? textMain : textLight)),
        ],
      ),
    );
  }

  // Preview existing foto dari server
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
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
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

  // Preview foto baru yang dipilih
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
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
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

  // Info nama file
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