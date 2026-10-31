import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Palet halaman approval. Sumber warna mengikuti web-goten/DESIGN.md dan
/// setiap pasangan teks sudah diukur lulus kontras AA.
class ApprovalPalette {
  const ApprovalPalette._();

  static const Color primary = Color(0xFF3B6DF0);
  static const Color primaryStrong = Color(0xFF2F5BE0);
  static const Color primaryInk = Color(0xFF2446B8);
  static const Color primarySoft = Color(0xFFEEF2FE);

  static const Color background = Color(0xFFF0F4FF);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color ink = Color(0xFF1A2233);
  static const Color body = Color(0xFF4B5563);
  static const Color meta = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color controlBorder = Color(0xFF8A94A6);

  static const Color success = Color(0xFF047857);
  static const Color successStrong = Color(0xFF00855A);
  static const Color successSoft = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFB45309);
  static const Color warningSoft = Color(0xFFFFF4EA);

  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFDECEC);
}

const String _buktiBaseUrl = 'http://103.103.22.7/cutikaryawan/bukti';

String approvalBuktiUrl(String namaFile) =>
    namaFile.trim().isEmpty ? '' : '$_buktiBaseUrl/${namaFile.trim()}';

String approvalFormatTanggal(DateTime tanggal) {
  try {
    return DateFormat('d MMM yyyy', 'id').format(tanggal);
  } catch (_) {
    // Data locale 'id' belum dimuat, pakai format bawaan.
    return DateFormat('d MMM yyyy').format(tanggal);
  }
}

/// Tanggal dari server bisa berupa DATE, DATETIME, atau ISO lengkap.
String approvalFormatTanggalDari(dynamic nilai) {
  if (nilai == null) return '';
  final teks = nilai.toString().trim();
  if (teks.isEmpty) return '';

  final cocok = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(teks);
  final tanggal = cocok != null
      ? DateTime.tryParse('${cocok.group(1)}-${cocok.group(2)}-${cocok.group(3)}')
      : DateTime.tryParse(teks);
  if (tanggal == null) return teks;
  return approvalFormatTanggal(tanggal);
}

String approvalFormatTanggalWaktu(dynamic nilai) {
  if (nilai == null) return '';
  final teks = nilai.toString().trim();
  if (teks.isEmpty) return '';

  final tanggal = DateTime.tryParse(teks);
  if (tanggal == null) return teks;

  try {
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(tanggal);
  } catch (_) {
    return DateFormat('d MMM yyyy, HH:mm').format(tanggal);
  }
}

enum ApprovalTone { primary, danger }

/// Label dan warna status. Hanya tiga keadaan yang dipakai backend.
class ApprovalStatus {
  const ApprovalStatus._(this.label, this.foreground, this.background, this.pending);

  final String label;
  final Color foreground;
  final Color background;
  final bool pending;

  static ApprovalStatus parse(String? mentah) {
    switch ((mentah ?? '').trim().toUpperCase()) {
      case 'ACCEPT':
        return const ApprovalStatus._('Disetujui', ApprovalPalette.success, ApprovalPalette.successSoft, false);
      case 'REJECT':
        return const ApprovalStatus._('Ditolak', ApprovalPalette.danger, ApprovalPalette.dangerSoft, false);
      default:
        return const ApprovalStatus._('Menunggu', ApprovalPalette.warning, ApprovalPalette.warningSoft, true);
    }
  }
}

class ApprovalStatusPill extends StatelessWidget {
  const ApprovalStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final gaya = ApprovalStatus.parse(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: gaya.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gaya.foreground.withOpacity(0.24)),
      ),
      child: Text(
        gaya.label,
        maxLines: 1,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: gaya.foreground, height: 1.2),
      ),
    );
  }
}

class ApprovalHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const ApprovalHeaderBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    this.refreshing = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRefresh;
  final bool refreshing;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: ApprovalPalette.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: ApprovalPalette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      shape: const Border(bottom: BorderSide(color: ApprovalPalette.border)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: ApprovalPalette.ink),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12, color: ApprovalPalette.meta),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: refreshing ? null : onRefresh,
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ApprovalPalette.primaryStrong),
                )
              : const Icon(Icons.refresh_rounded, size: 22, color: ApprovalPalette.primaryStrong),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class ApprovalFilterBar extends StatelessWidget {
  const ApprovalFilterBar({
    super.key,
    required this.start,
    required this.end,
    required this.status,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onStatusChanged,
  });

  final DateTime start;
  final DateTime end;
  final String status;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onStatusChanged;

  static const List<_StatusOption> _opsi = [
    _StatusOption('PENDING', 'Menunggu'),
    _StatusOption('ACCEPT', 'Disetujui'),
    _StatusOption('REJECT', 'Ditolak'),
    _StatusOption('ALL', 'Semua'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ApprovalPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ApprovalPalette.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _DateField(label: 'Dari', value: start, onTap: onPickStart)),
              const SizedBox(width: 10),
              Expanded(child: _DateField(label: 'Sampai', value: end, onTap: onPickEnd)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 50,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: ApprovalPalette.primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ApprovalPalette.border),
            ),
            child: Row(
              children: _opsi.map((opsi) {
                final aktif = opsi.value == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      selected: aktif,
                      button: true,
                      child: Material(
                        color: aktif ? ApprovalPalette.primaryStrong : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => onStatusChanged(opsi.value),
                          borderRadius: BorderRadius.circular(8),
                          child: Center(
                            child: Text(
                              opsi.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: aktif ? Colors.white : ApprovalPalette.body,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption(this.value, this.label);
  final String value;
  final String label;
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label ${approvalFormatTanggal(value)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ApprovalPalette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ApprovalPalette.controlBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: ApprovalPalette.meta, height: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        approvalFormatTanggal(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ApprovalPalette.ink, height: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_rounded, size: 16, color: ApprovalPalette.primaryStrong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApprovalInfoRow extends StatelessWidget {
  const ApprovalInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: ApprovalPalette.meta, height: 1.45),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: ApprovalPalette.ink, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalPhotoThumb extends StatelessWidget {
  const ApprovalPhotoThumb({super.key, required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lihat bukti foto',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    cacheWidth: 192,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: ApprovalPalette.primarySoft,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ApprovalPalette.primaryStrong),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: ApprovalPalette.dangerSoft,
                      child: const Icon(Icons.broken_image_outlined, size: 20, color: ApprovalPalette.danger),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bukti foto',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ApprovalPalette.primaryStrong),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ketuk untuk memperbesar',
                      style: GoogleFonts.inter(fontSize: 11, color: ApprovalPalette.meta),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_full_rounded, size: 18, color: ApprovalPalette.meta),
            ],
          ),
        ),
      ),
    );
  }
}

class ApprovalCardShell extends StatelessWidget {
  const ApprovalCardShell({
    super.key,
    required this.nama,
    required this.meta,
    required this.status,
    this.children = const [],
    this.footer,
  });

  final String nama;
  final String meta;
  final String status;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ApprovalPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ApprovalPalette.border),
        boxShadow: const [BoxShadow(color: Color(0x0D1A2233), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InitialAvatar(nama: nama),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: ApprovalPalette.ink, height: 1.25),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: ApprovalPalette.meta, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ApprovalStatusPill(status: status),
            ],
          ),
          ...children,
          if (footer != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: ApprovalPalette.border),
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.nama});

  final String nama;

  String get _inisial {
    final bagian = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (bagian.isEmpty) return '?';
    if (bagian.length == 1) return bagian.first.substring(0, 1).toUpperCase();
    return '${bagian[0].substring(0, 1)}${bagian[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: ApprovalPalette.primarySoft, shape: BoxShape.circle),
      child: Text(
        _inisial,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ApprovalPalette.primaryInk),
      ),
    );
  }
}

class ApprovalActionBar extends StatelessWidget {
  const ApprovalActionBar({
    super.key,
    required this.busy,
    required this.enabled,
    required this.onReject,
    required this.onAccept,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ApprovalPalette.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: ApprovalPalette.primaryStrong),
            ),
            const SizedBox(width: 10),
            Text(
              'Memproses...',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ApprovalPalette.primaryStrong),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: enabled ? onReject : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: ApprovalPalette.danger,
                backgroundColor: ApprovalPalette.surface,
                side: BorderSide(color: enabled ? ApprovalPalette.danger : ApprovalPalette.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Tolak', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: enabled ? onAccept : null,
              style: FilledButton.styleFrom(
                backgroundColor: ApprovalPalette.successStrong,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ApprovalPalette.border,
                disabledForegroundColor: ApprovalPalette.meta,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Terima', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

class ApprovalLoadingState extends StatelessWidget {
  const ApprovalLoadingState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: ApprovalPalette.primaryStrong),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: ApprovalPalette.body),
            ),
          ],
        ),
      ),
    );
  }
}

/// Membungkus state kosong/error/loading agar tetap terpusat saat ruang cukup,
/// tapi bisa digulir saat layar pendek atau ukuran teks sistem diperbesar.
class ApprovalStateSliver extends StatelessWidget {
  const ApprovalStateSliver({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ApprovalEmptyState extends StatelessWidget {
  const ApprovalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = ApprovalTone.primary,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final ApprovalTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final warna = tone == ApprovalTone.danger ? ApprovalPalette.danger : ApprovalPalette.primaryInk;
    final latar = tone == ApprovalTone.danger ? ApprovalPalette.dangerSoft : ApprovalPalette.primarySoft;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: latar, shape: BoxShape.circle),
              child: Icon(icon, size: 26, color: warna),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: ApprovalPalette.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: ApprovalPalette.body, height: 1.5),
            ),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: ApprovalPalette.primaryStrong,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ApprovalErrorState extends StatelessWidget {
  const ApprovalErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: ApprovalPalette.dangerSoft, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 26, color: ApprovalPalette.danger),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: ApprovalPalette.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: ApprovalPalette.body, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: ApprovalPalette.primaryStrong,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Coba lagi', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showTolakDialog(
  BuildContext context, {
  required String judul,
  required String pesan,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ApprovalPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        judul,
        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: ApprovalPalette.ink),
      ),
      content: Text(
        pesan,
        style: GoogleFonts.inter(fontSize: 14, color: ApprovalPalette.body, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: ApprovalPalette.body,
            minimumSize: const Size(0, 44),
          ),
          child: Text('Batal', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: ApprovalPalette.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Tolak pengajuan', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

Future<void> showApprovalPhotoDialog(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xB31A2233),
    builder: (dialogContext) {
      final tinggiMaks = MediaQuery.sizeOf(dialogContext).height * 0.75;
      return Dialog(
        backgroundColor: ApprovalPalette.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: tinggiMaks),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 4, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bukti foto',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ApprovalPalette.ink),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22, color: ApprovalPalette.body),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: ApprovalPalette.primaryStrong),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_outlined, size: 32, color: ApprovalPalette.danger),
                          const SizedBox(height: 8),
                          Text(
                            'Foto tidak dapat dimuat',
                            style: GoogleFonts.inter(fontSize: 13, color: ApprovalPalette.body),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

void showApprovalSnack(BuildContext context, String pesan, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(pesan, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
      backgroundColor: error ? ApprovalPalette.danger : ApprovalPalette.successStrong,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}
