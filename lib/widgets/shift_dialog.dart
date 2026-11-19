import 'package:flutter/material.dart';
import '../services/absensi_service.dart';

// Warna aksi dialog: hijau untuk semua (masuk & keluar). Kontras lolos WCAG AA
// (dicek via contrast-check.py: putih di atas #047857 = 5.48:1).
const Color _green = Color(0xFF047857);
const Color _greenSoft = Color(0xFFE7F6EF);

// Identitas visual per shift: warna diambil dari waktu hari (pagi=amber, siang=oranye,
// malam=indigo). Fungsional, membantu pekerja pabrik mengenali shift sekilas tanpa baca teks.
// cakupan ikon: glyph waktu-hari relevan dengan nama shift. Day Shift (0) netral.
class _ShiftMeta {
  final IconData icon;
  final Color tint;
  final Color fg;
  final String nama;

  const _ShiftMeta(this.icon, this.tint, this.fg, this.nama);
}

const Map<int, _ShiftMeta> _meta = {
  0: _ShiftMeta(Icons.wb_sunny_outlined, Color(0xFFECFDF5), Color(0xFF047857), 'Day Shift'),
  1: _ShiftMeta(Icons.wb_sunny_outlined, Color(0xFFFFF4D1), Color(0xFF92400E), 'Pagi'),
  2: _ShiftMeta(Icons.wb_twilight, Color(0xFFFFE9D6), Color(0xFF9A3412), 'Siang'),
  3: _ShiftMeta(Icons.bedtime_outlined, Color(0xFFE7EAFB), Color(0xFF3730A3), 'Malam'),
};

String namaShiftServer(List shifts, int kd) {
  for (final s in shifts) {
    if (s is Map && s['kd_shift'] == kd) {
      final mentah = (s['nm_shift'] ?? '').toString().trim();
      if (mentah.isNotEmpty) {
        return mentah
            .toLowerCase()
            .split(' ')
            .where((k) => k.isNotEmpty)
            .map((k) => k[0].toUpperCase() + k.substring(1))
            .join(' ');
      }
    }
  }
  return _meta[kd]?.nama ?? '';
}

String _ddMyyyy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

// Konfirmasi shift saat check-in/check-out.
// Kembalikan kd_shift terpilih, atau null jika dibatalkan / gagal.
Future<int?> showShiftDialog(
  BuildContext context, {
  required String aksi,
  required String karNik,
  List<int> openShift = const [],
  int status = 1,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ShiftSheet(
      aksi: aksi,
      karNik: karNik,
      openShift: openShift,
      status: status,
    ),
  );
}

// Tampilkan dialog shift lalu submit. Minta ulang dialog hanya kalau server bilang
// shift itu sudah terisi (kode 'duplicate'), supaya user bisa pindah shift.
// 'no_open_session' dihentikan: menutup sesi di shift lain butuh dialog, bukan loop.
Future<AbsensiResult> submitAbsensiWithShift(
  BuildContext context, {
  required String aksi,
  required String karNik,
  required String kdCabang,
  required String latitude,
  required String longitude,
  required int status,
  List<int> openShift = const [],
  String? kdUnit,
}) async {
  final shift = await showShiftDialog(
    context,
    aksi: aksi,
    karNik: karNik,
    openShift: openShift,
    status: status,
  );
  if (shift == null || !context.mounted) {
    return const AbsensiResult(
        success: false, message: 'Dibatalkan', code: 'cancelled');
  }

  return AbsensiService.submitAbsensi(
    karNik: karNik,
    kdCabang: kdCabang,
    latitude: latitude,
    longitude: longitude,
    status: status,
    shift: shift,
    kdUnit: kdUnit,
  );
}

class _ShiftSheet extends StatefulWidget {
  final String aksi;
  final String karNik;
  final List<int> openShift;
  final int status;

  const _ShiftSheet({
    required this.aksi,
    required this.karNik,
    this.openShift = const [],
    this.status = 1,
  });

  @override
  State<_ShiftSheet> createState() => _ShiftSheetState();
}

class _ShiftSheetState extends State<_ShiftSheet> {
  late List _shifts;
  bool _loading = true;
  bool _failed = false;
  int? _selected;
  int? _recommended;

  bool get _isIn => widget.aksi == 'Check In';
  Color get _accent => _green;
  Color get _accentSoft => _greenSoft;
  String _nama(int kd) => namaShiftServer(_shifts, kd);

  // Shift yang bisa dipilih saat check-out: yang punya check-in (terbuka atau sudah
  // tertutup, asalkan masih dalam batas 3x / 18 jam di server).
  List<int> get _openShift =>
      widget.status == 2 ? widget.openShift : const <int>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final data = await AbsensiService.getShifts(widget.karNik);
    if (!mounted) return;

    final list = data?['data'];
    if (list is! List || list.isEmpty) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    // Default dari server. Untuk check-out, pilih shift yang sesinya masih terbuka.
    var defaultShift = ((data?['default_shift'] as num?) ?? 0).toInt();
    if (!_isIn && _openShift.isNotEmpty && !_openShift.contains(defaultShift)) {
      defaultShift = _openShift.last;
    }

    setState(() {
      _shifts = list;
      _loading = false;
      _selected = defaultShift;
      _recommended = defaultShift;
    });
  }

  // Server yang menentukan tanggal kerja (dari sesi check-in yang terbuka),
  // jadi preview di sini cukup menampilkan tanggal hari ini.
  String _kerjaPreview(int kd) {
    final now = DateTime.now();
    return _ddMyyyy(DateTime(now.year, now.month, now.day));
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Menyiapkan pilihan shift…'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, color: Colors.grey.shade500, size: 30),
          const SizedBox(height: 10),
          const Text('Gagal memuat daftar shift.'),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _load,
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    if (_isIn) return const SizedBox.shrink();
    if (_openShift.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline, size: 18, color: Color(0xFF92400E)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tidak ada shift yang sudah kamu Check In. Check Out hanya bisa untuk shift yang ada proses masuknya.',
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTile(int kd) {
    final m = _shifts.firstWhere((s) => (s as Map)['kd_shift'] == kd, orElse: () => null) as Map?;
    if (m == null) return const SizedBox.shrink();
    final meta = _meta[kd]!;
    final mulai = m['jam_mulai'];
    final selesai = m['jam_selesai'];
    // Day Shift tidak punya jadwal jam.
    final jam = (mulai == null || selesai == null) ? 'Absensi harian' : '$mulai - $selesai';
    final selected = _selected == kd;
    final recommended = _recommended == kd;

    // Check-out hanya boleh untuk shift yang masih terbuka; shift lain tidak bisa dipilih.
    if (!_isIn && !_openShift.contains(kd)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? _accentSoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selected = kd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _accent : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: meta.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(meta.icon, color: meta.fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shift $kd (${_nama(kd)})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              jam,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recommended) ..._pill('Disarankan'),
                      const SizedBox(width: 6),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected ? _accent : Colors.grey.shade400,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _pill(String teks) {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          teks,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final aksi = widget.aksi;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isIn ? Icons.login : Icons.logout,
                    color: _accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih shift untuk $aksi',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isIn
                            ? 'Tentukan shift tempat kamu masuk bekerja.'
                            : 'Tentukan shift yang kamu tinggalkan.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              _buildLoading()
            else if (_failed)
              _buildError()
            else ...[
              _buildNote(),
              ..._shifts.map((s) => _buildTile(((s as Map)['kd_shift'] as num).toInt())),
              if (_isIn) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kerja dicatat: ${_kerjaPreview(_selected ?? 0)}',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: (!_isIn && _openShift.isEmpty)
                    ? null
                    : () => Navigator.pop(context, _selected ?? _recommended ?? 0),
                child: Text(
                    'Konfirmasi $aksi · ${_nama(_selected ?? _recommended ?? 0)}'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}