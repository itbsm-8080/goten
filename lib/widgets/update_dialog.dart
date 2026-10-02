import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/update_service.dart';

const _biru = Color(0xFF3B6DF0);

/// Dialog pembaruan aplikasi.
///
/// [wajib] = true: tidak ada jalan keluar, app belum boleh dipakai sampai versi ini
/// terpasang. Nilai ini datang dari server lewat `InfoUpdate.wajib`.
Future<void> showDialogUpdate(BuildContext context, InfoUpdate info) {
  return showDialog(
    context: context,
    barrierDismissible: !info.wajib,
    builder: (ctx) => PopScope(
      canPop: !info.wajib,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          info.wajib ? 'Pembaruan diperlukan' : 'Ada versi baru',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_ringkasan(info),
                style: GoogleFonts.inter(fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 14),
            _ProgressUnduh(),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [_TombolPasang(info, ctx)],
      ),
    ),
  );
}

String _ringkasan(InfoUpdate info) {
  final versi =
      info.versionName.isEmpty ? '' : 'Versi ${info.versionName}.';
  if (info.wajib) {
    return 'Aplikasi belum bisa dipakai sampai pembaruan ini selesai'
        '${info.catatan.isEmpty ? '' : ': ${info.catatan}'}. '
        '$versi';
  }
  if (info.catatan.isEmpty) return '$versi Sudah bisa dipasang sekarang.';
  return '${info.catatan}. $versi';
}

class _ProgressUnduh extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DownloadUpdate>(
      stream: UpdateService.lajuUnduhan,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) return const SizedBox.shrink();
        final persen = d.total > 0 ? (d.diterima / d.total * 100).round() : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: d.total > 0 ? d.diterima / d.total : null,
                minHeight: 5,
                backgroundColor: _biru.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(_biru),
              ),
            ),
            const SizedBox(height: 6),
            Text('$persen% · ${(d.diterima / 1048576).toStringAsFixed(1)} MB',
                style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade600)),
          ],
        );
      },
    );
  }
}

class _TombolPasang extends StatefulWidget {
  const _TombolPasang(this.info, this.ctx);
  final InfoUpdate info;
  final BuildContext ctx;

  @override
  State<_TombolPasang> createState() => _TombolPasangState();
}

class _TombolPasangState extends State<_TombolPasang> {
  bool _sibuk = false;
  String? _galat;

  Future<void> _pasang() async {
    // Dialog bisa sudah tertutup saat unduhan berjalan, jadi navigator dan
    // messenger diambil lebih dulu - setelah await, context bisa tidak valid lagi.
    final navigator = Navigator.of(widget.ctx);
    final messenger = ScaffoldMessenger.of(widget.ctx);
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      await UpdateService.unduhDanPasang(widget.info);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Selesaikan pemasangan di layar Android',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00C897),
      ));
    } on GagalUpdate catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } catch (e) {
      if (mounted) setState(() => _galat = 'Gagal memasang update');
    }
    if (mounted) setState(() => _sibuk = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_galat != null) ...[
          Text(_galat!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700)),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: _sibuk ? null : _pasang,
          style: TextButton.styleFrom(
            backgroundColor: _sibuk ? _biru.withOpacity(0.4) : _biru,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            _sibuk ? 'Mengunduh' : 'Perbarui Sekarang',
            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}