import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:goten/services/izin_service.dart';
import 'package:goten/widgets/approval_ui.dart';

class ApprovalIzinPage extends StatefulWidget {
  final String? karNik;
  final List<String> kdUnits;
  const ApprovalIzinPage({super.key, this.karNik, this.kdUnits = const []});

  @override
  State<ApprovalIzinPage> createState() => _ApprovalIzinPageState();
}

class _ApprovalIzinPageState extends State<ApprovalIzinPage> {
  List<dynamic> _items = [];
  List<String> _kdUnits = [];
  bool _isApprover = false;
  bool _isCheckingRole = true;
  bool _roleError = false;
  bool _isLoading = true;
  String? _error;
  String _busyNomor = '';

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _statusFilter = 'PENDING';

  @override
  void initState() {
    super.initState();
    _kdUnits = widget.kdUnits.where((e) => e.trim().isNotEmpty).toList();
    if (_kdUnits.isNotEmpty) {
      // Dashboard hanya mengirim unit ke approver, jadi daftar bisa langsung dimuat
      // tanpa menunggu cek role dan tanpa sempat menampilkan layar tanpa akses.
      _isApprover = true;
      _isCheckingRole = false;
      _loadApproval();
    } else {
      _cekRole();
    }
  }

  Future<void> _cekRole() async {
    final response = await IzinService.cekRoleApproval(widget.karNik ?? '');
    if (!mounted) return;

    if (response == null) {
      setState(() {
        _isCheckingRole = false;
        _roleError = true;
        _isLoading = false;
      });
      return;
    }

    final units = (response['kd_units'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        <String>[];
    final approver = response['is_approver'] == true;

    setState(() {
      _isCheckingRole = false;
      _roleError = false;
      _isApprover = approver;
      _kdUnits = units;
    });

    if (approver && units.isNotEmpty) {
      await _loadApproval();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _retryRole() async {
    setState(() {
      _isCheckingRole = true;
      _roleError = false;
    });
    await _cekRole();
  }

  Future<void> _loadApproval() async {
    if (_kdUnits.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await IzinService.getApprovalList(
        kdUnits: _kdUnits,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        status: _statusFilter,
      );
      if (!mounted) return;

      if (response == null) {
        _gagalMuat('Server tidak merespons. Periksa koneksi lalu coba lagi.');
        return;
      }

      final data = response['data'];
      setState(() {
        _items = data is List ? data : <dynamic>[];
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      _gagalMuat('Pengajuan gagal dimuat. Periksa koneksi lalu coba lagi.');
    }
  }

  void _gagalMuat(String pesan) {
    setState(() {
      _isLoading = false;
      // Daftar lama tetap ditampilkan; kegagalan penyegaran cukup lewat snackbar.
      _error = _items.isEmpty ? pesan : null;
    });
    if (_items.isNotEmpty) {
      showApprovalSnack(context, pesan, error: true);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: isStart ? 'Pilih tanggal mulai' : 'Pilih tanggal akhir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(picked)) _startDate = picked;
      }
    });
    await _loadApproval();
  }

  Future<void> _ubahStatus(String status) async {
    if (status == _statusFilter) return;
    setState(() => _statusFilter = status);
    await _loadApproval();
  }

  Future<void> _resetFilter() async {
    final now = DateTime.now();
    setState(() {
      _statusFilter = 'PENDING';
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
    await _loadApproval();
  }

  Future<void> _proses(String nomor, String status) async {
    if (nomor.isEmpty || _busyNomor.isNotEmpty) return;

    setState(() => _busyNomor = nomor);
    final berhasil = await IzinService.prosesIzin(nomor, status, karNik: widget.karNik);
    if (!mounted) return;

    setState(() => _busyNomor = '');
    if (!berhasil) {
      showApprovalSnack(context, 'Pengajuan gagal diproses. Coba lagi.', error: true);
      return;
    }

    showApprovalSnack(
      context,
      status == 'ACCEPT' ? 'Pengajuan izin diterima.' : 'Pengajuan izin ditolak.',
    );
    await _loadApproval();
  }

  Future<void> _tolak(dynamic izin) async {
    final nama = (izin['kar_nama'] ?? 'karyawan').toString();
    final tanggal = approvalFormatTanggalWaktu(izin['tanggal']);
    final yakin = await showTolakDialog(
      context,
      judul: 'Tolak pengajuan izin?',
      pesan: tanggal.isEmpty
          ? 'Pengajuan izin dari $nama akan ditandai ditolak. Periksa kembali sebelum melanjutkan.'
          : 'Pengajuan izin dari $nama tanggal $tanggal akan ditandai ditolak. Periksa kembali sebelum melanjutkan.',
    );
    if (!yakin || !mounted) return;
    await _proses((izin['ij_nomor'] ?? '').toString(), 'REJECT');
  }

  bool get _filterDiubah {
    final now = DateTime.now();
    final awalBulan = DateTime(now.year, now.month, 1);
    return _statusFilter != 'PENDING' ||
        _startDate.year != awalBulan.year ||
        _startDate.month != awalBulan.month ||
        _startDate.day != awalBulan.day ||
        _endDate.year != now.year ||
        _endDate.month != now.month ||
        _endDate.day != now.day;
  }

  String get _emptyMessage {
    if (_statusFilter == 'PENDING') {
      return 'Tidak ada pengajuan yang menunggu persetujuan pada rentang tanggal ini.';
    }
    return 'Tidak ada pengajuan pada rentang tanggal dan status yang dipilih.';
  }

  String get _subtitle {
    if (_isCheckingRole) return 'Memeriksa akses...';
    if (_roleError) return 'Akses belum dapat diperiksa';
    if (!_isApprover) return 'Hanya untuk atasan unit';
    if (_isLoading && _items.isEmpty) return 'Memuat pengajuan...';
    if (_items.isEmpty) return 'Tidak ada pengajuan';
    if (_statusFilter == 'PENDING') return '${_items.length} menunggu persetujuan';
    return '${_items.length} pengajuan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApprovalPalette.background,
      appBar: ApprovalHeaderBar(
        title: 'Approval Izin',
        subtitle: _subtitle,
        refreshing: _isCheckingRole || (_isLoading && _items.isNotEmpty),
        onRefresh: _isApprover ? _loadApproval : _retryRole,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isCheckingRole) {
      return const ApprovalLoadingState(message: 'Memeriksa akses...');
    }
    if (_roleError) {
      return ApprovalErrorState(
        title: 'Akses belum dapat diperiksa',
        message: 'Periksa koneksi internet lalu coba lagi.',
        onRetry: _retryRole,
      );
    }
    if (!_isApprover) {
      return const ApprovalEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Tidak ada akses',
        message: 'Halaman ini hanya untuk atasan unit.',
      );
    }
    if (_kdUnits.isEmpty) {
      return const ApprovalEmptyState(
        icon: Icons.apartment_rounded,
        title: 'Belum ada unit',
        message: 'Akun Anda belum terhubung ke unit kerja. Hubungi admin untuk menautkannya.',
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: ApprovalFilterBar(
            start: _startDate,
            end: _endDate,
            status: _statusFilter,
            onPickStart: () => _pickDate(isStart: true),
            onPickEnd: () => _pickDate(isStart: false),
            onStatusChanged: _ubahStatus,
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: ApprovalPalette.primaryStrong,
      onRefresh: _loadApproval,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_isLoading && _items.isEmpty)
            const ApprovalStateSliver(
              child: ApprovalLoadingState(message: 'Memuat pengajuan...'),
            )
          else if (_error != null)
            ApprovalStateSliver(
              child: ApprovalErrorState(
                title: 'Pengajuan gagal dimuat',
                message: _error!,
                onRetry: _loadApproval,
              ),
            )
          else if (_items.isEmpty)
            ApprovalStateSliver(
              child: ApprovalEmptyState(
                icon: Icons.inbox_rounded,
                title: 'Tidak ada pengajuan',
                message: _emptyMessage,
                actionLabel: _filterDiubah ? 'Atur ulang filter' : null,
                onAction: _filterDiubah ? _resetFilter : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: index == _items.length - 1 ? 0 : 12),
                    child: _buildCard(_items[index]),
                  ),
                  childCount: _items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic izin) {
    final status = (izin['ij_status'] ?? 'PENDING').toString();
    final isPending = ApprovalStatus.parse(status).pending;
    final nomor = (izin['ij_nomor'] ?? '').toString();
    final nama = (izin['kar_nama'] ?? 'Tanpa nama').toString();
    final unit = (izin['nm_unit'] ?? '').toString().trim();
    final tanggal = approvalFormatTanggalWaktu(izin['tanggal']);
    final alasan = (izin['alasan'] ?? '').toString().trim();
    final keterangan = (izin['keterangan'] ?? '').toString().trim();
    final fotoUrl = approvalBuktiUrl((izin['ij_foto'] ?? '').toString());

    final meta = [if (unit.isNotEmpty) unit, if (tanggal.isNotEmpty) tanggal].join(' · ');

    return ApprovalCardShell(
      nama: nama,
      meta: meta,
      status: status,
      footer: isPending
          ? ApprovalActionBar(
              busy: _busyNomor == nomor,
              enabled: _busyNomor.isEmpty,
              onReject: () => _tolak(izin),
              onAccept: () => _proses(nomor, 'ACCEPT'),
            )
          : null,
      children: [
        ApprovalInfoRow(label: 'Alasan', value: alasan.isEmpty ? 'Tidak disebutkan' : alasan),
        if (keterangan.isNotEmpty) ApprovalInfoRow(label: 'Keterangan', value: keterangan),
        if (fotoUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ApprovalPhotoThumb(
              url: fotoUrl,
              onTap: () => showApprovalPhotoDialog(context, fotoUrl),
            ),
          ),
      ],
    );
  }
}
