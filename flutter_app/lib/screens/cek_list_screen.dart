import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/unit.dart';
import '../models/ruang.dart';
import '../models/barang_cek.dart';

const _primary = Color(0xFF4F46E5);
const _primaryDark = Color(0xFF312E81);
const _bg = Color(0xFFF5F5FB);
const _ink = Color(0xFF111827);
const _inkSoft = Color(0xFF6B7280);
const _inkFaint = Color(0xFF9CA3AF);
const _line = Color(0xFFECEEF3);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFEF4444);
const _info = Color(0xFF2563EB);

class CekListScreen extends StatefulWidget {
  const CekListScreen({super.key});

  @override
  State<CekListScreen> createState() => _CekListScreenState();
}

class _CekListScreenState extends State<CekListScreen> {
  final _searchController = TextEditingController();

  List<Unit> _units = [];
  List<Ruang> _ruangs = [];
  List<BarangCek> _items = [];

  int? _selectedUnitId;
  int? _selectedRuangId;

  int _totalCount = 0;
  int _checkedCount = 0;
  int _uncheckedCount = 0;

  bool _isLoadingUnits = true;
  bool _isLoadingRuang = false;
  bool _isLoadingItems = false;
  bool _hasPeriode = true;
  String? _periodeInfo;

  final Set<int> _actionLoading = {};

  final int? _currentUserId = AuthService.currentUser?.id;
  final String _currentUserName = AuthService.currentUser?.namaLengkap ?? '';

  @override
  void initState() {
    super.initState();
    _loadPeriodeInfo();
    _loadUnits();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================
  Future<void> _loadPeriodeInfo() async {
    final result = await ApiService.getDashboard();
    if (!mounted || result['success'] != true) return;
    final periode = result['data']['periode_aktif'];
    setState(() {
      if (periode != null) {
        _periodeInfo =
            '${periode['nama_periode']} (Batas akhir: ${periode['tgl_selesai']})';
        _hasPeriode = true;
      } else {
        _hasPeriode = false;
      }
    });
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoadingUnits = true);
    final result = await ApiService.getUnits();
    if (!mounted) return;
    setState(() {
      _isLoadingUnits = false;
      if (result['success'] == true) {
        _units = (result['data'] as List).cast<Unit>();
      }
    });
  }

  Future<void> _onUnitChanged(int? unitId) async {
    setState(() {
      _selectedUnitId = unitId;
      _selectedRuangId = null;
      _ruangs = [];
      _items = [];
      _totalCount = 0;
      _checkedCount = 0;
      _uncheckedCount = 0;
    });

    if (unitId == null) return;

    setState(() => _isLoadingRuang = true);
    final result = await ApiService.getRuang(unitId);
    if (!mounted) return;
    setState(() {
      _isLoadingRuang = false;
      if (result['success'] == true) {
        _ruangs = (result['data'] as List).cast<Ruang>();
      }
    });
  }

  Future<void> _applyFilter() async {
    if (_selectedUnitId == null || _selectedRuangId == null) return;

    setState(() => _isLoadingItems = true);
    final result = await ApiService.getBarangRuang(_selectedUnitId!, _selectedRuangId!);
    if (!mounted) return;

    setState(() {
      _isLoadingItems = false;
      if (result['success'] == true) {
        _items = (result['data'] as List).cast<BarangCek>();
        final summary = result['summary'] as Map<String, dynamic>?;
        _totalCount = summary?['total'] ?? _items.length;
        _checkedCount = summary?['checked'] ?? 0;
        _uncheckedCount = summary?['unchecked'] ?? 0;
      }
    });

    if (result['success'] != true) {
      _showSnack(result['message'] ?? 'Gagal memuat daftar barang', _danger, Icons.error_rounded);
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================
  Future<void> _doCheckBaik(BarangCek item) async {
    setState(() => _actionLoading.add(item.id));
    final result = await ApiService.checkBaik(item.id);
    if (!mounted) return;
    setState(() => _actionLoading.remove(item.id));

    if (result['success'] == true) {
      HapticFeedback.mediumImpact();
      final petugas = result['petugas']?.toString() ?? _currentUserName;
      setState(() {
        final wasChecked = item.isChecked;
        _items = _items.map((e) {
          if (e.id != item.id) return e;
          return BarangCek(
            id: e.id,
            formattedCode: e.formattedCode,
            namaBarang: e.namaBarang,
            kondisi: 'Baik',
            isChecked: true,
            kondisiTemuan: 'Baik',
            statusReview: 'disetujui',
            idPetugas: _currentUserId,
            namaPetugas: petugas,
          );
        }).toList();
        if (!wasChecked) {
          _checkedCount += 1;
          _uncheckedCount = (_uncheckedCount - 1).clamp(0, 1 << 31);
        }
      });
      _showSnack(result['message'] ?? 'Berhasil disimpan', _success, Icons.check_circle_rounded);
    } else {
      _showSnack(result['message'] ?? 'Gagal menyimpan', _danger, Icons.error_rounded);
    }
  }

  Future<void> _doBatal(BarangCek item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Batalkan pengecekan?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Status pengecekan barang ini akan dihapus & kembali menjadi "Belum Dicek".',
          style: GoogleFonts.inter(fontSize: 13, color: _inkSoft, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Kembali', style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ya, Batalkan!', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionLoading.add(item.id));
    final result = await ApiService.batalCheck(item.id);
    if (!mounted) return;
    setState(() => _actionLoading.remove(item.id));

    if (result['success'] == true) {
      HapticFeedback.mediumImpact();
      setState(() {
        final wasChecked = item.isChecked;
        _items = _items.map((e) {
          if (e.id != item.id) return e;
          return BarangCek(
            id: e.id,
            formattedCode: e.formattedCode,
            namaBarang: e.namaBarang,
            kondisi: e.kondisi,
            isChecked: false,
            kondisiTemuan: null,
            statusReview: null,
            idPetugas: null,
            namaPetugas: null,
          );
        }).toList();
        if (wasChecked) {
          _checkedCount = (_checkedCount - 1).clamp(0, 1 << 31);
          _uncheckedCount += 1;
        }
      });
      _showSnack(result['message'] ?? 'Pengecekan dibatalkan', _info, Icons.info_rounded);
    } else {
      _showSnack(result['message'] ?? 'Gagal membatalkan', _danger, Icons.error_rounded);
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  List<BarangCek> get _filteredItems {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where((e) =>
            e.namaBarang.toLowerCase().contains(q) ||
            e.formattedCode.toLowerCase().contains(q) ||
            e.id.toString().contains(q))
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Cek List',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (_hasPeriode && _periodeInfo != null) _buildPeriodeBanner(),
            if (!_hasPeriode) _buildNoPeriodeBanner(),
            const SizedBox(height: 16),
            _buildFilterCard(),
            const SizedBox(height: 16),
            if (_items.isNotEmpty || _isLoadingItems) ...[
              _buildSummaryRow(),
              const SizedBox(height: 16),
              _buildSearchField(),
              const SizedBox(height: 12),
            ],
            _buildListSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.info_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode Aktif',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _periodeInfo!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPeriodeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tidak ada periode pengecekan aktif. Anda belum dapat melakukan pengecekan.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF92400E), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_rounded, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filter Unit & Ruangan',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Unit / Unit Kerja'),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedUnitId,
            isExpanded: true,
            decoration: _dropdownDecoration(),
            hint: Text(
              _isLoadingUnits ? 'Memuat unit...' : '-- Pilih Unit --',
              style: GoogleFonts.inter(fontSize: 13.5, color: _inkFaint),
            ),
            items: _units
                .map((u) => DropdownMenuItem<int>(
                      value: u.id,
                      child: Text(u.namaUnit,
                          style: GoogleFonts.inter(fontSize: 13.5, color: _ink)),
                    ))
                .toList(),
            onChanged: _isLoadingUnits ? null : _onUnitChanged,
          ),
          const SizedBox(height: 14),
          _label('Ruangan'),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedRuangId,
            isExpanded: true,
            decoration: _dropdownDecoration(),
            hint: Text(
              _isLoadingRuang
                  ? 'Memuat ruangan...'
                  : (_selectedUnitId == null ? 'Pilih unit dahulu' : '-- Pilih Ruangan --'),
              style: GoogleFonts.inter(fontSize: 13.5, color: _inkFaint),
            ),
            items: _ruangs
                .map((r) => DropdownMenuItem<int>(
                      value: r.id,
                      child: Text(r.namaRuang,
                          style: GoogleFonts.inter(fontSize: 13.5, color: _ink)),
                    ))
                .toList(),
            onChanged: (_selectedUnitId == null || _isLoadingRuang)
                ? null
                : (v) => setState(() => _selectedRuangId = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_selectedUnitId != null && _selectedRuangId != null && !_isLoadingItems)
                  ? _applyFilter
                  : null,
              icon: _isLoadingItems
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Icon(Icons.search_rounded, size: 20),
              label: Text(
                'Terapkan',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _inkSoft),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.inventory_2_rounded,
            label: 'Total Barang',
            value: _totalCount,
            color: _info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_rounded,
            label: 'Sudah Dicek',
            value: _checkedCount,
            color: _success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.schedule_rounded,
            label: 'Belum Dicek',
            value: _uncheckedCount,
            color: _inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10.5, color: _inkFaint, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.inter(fontSize: 14, color: _ink),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _inkFaint),
        hintText: 'Cari barang...',
        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: _inkFaint),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildListSection() {
    if (_isLoadingItems) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (_selectedUnitId == null || _selectedRuangId == null) {
      return _buildPlaceholder(
        icon: Icons.filter_alt_rounded,
        title: 'Pilih Lokasi Terlebih Dahulu',
        subtitle:
            'Tentukan Unit Kerja dan Ruangan pada filter di atas, lalu klik Terapkan untuk menampilkan daftar aset.',
      );
    }

    final items = _filteredItems;
    if (items.isEmpty) {
      return _buildPlaceholder(
        icon: Icons.inbox_rounded,
        title: 'Tidak ada data',
        subtitle: _searchController.text.trim().isEmpty
            ? 'Tidak ada barang aktif di ruangan ini.'
            : 'Tidak ada barang yang cocok dengan pencarian.',
      );
    }

    return Column(
      children: items.map(_buildItemCard).toList(),
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _inkSoft),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.5, color: _inkFaint, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BarangCek item) {
    final loading = _actionLoading.contains(item.id);
    final isOwn = item.isChecked && item.idPetugas == _currentUserId;
    final isBaik = item.isChecked && item.kondisiTemuan == 'Baik';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.formattedCode,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _inkFaint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.namaBarang,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(item),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionArea(item, isOwn, isBaik, loading)),
              if (isOwn) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: loading ? null : () => _doBatal(item),
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _danger,
                    side: const BorderSide(color: _danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BarangCek item) {
    if (!item.isChecked) {
      return _badge('Belum Dicek', _inkSoft);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _badge('Sudah Dicek', _success),
        if ((item.namaPetugas ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Oleh: ${item.namaPetugas}',
            style: GoogleFonts.inter(fontSize: 10.5, color: _inkFaint),
          ),
        ],
      ],
    );
  }

  Widget _buildActionArea(BarangCek item, bool isOwn, bool isBaik, bool loading) {
    if (!item.isChecked) {
      return SizedBox(
        height: 40,
        child: ElevatedButton.icon(
          onPressed: loading ? null : () => _doCheckBaik(item),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : const Icon(Icons.bolt_rounded, size: 18),
          label: Text('Baik', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _success,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    if (isBaik) {
      return _statusPill('Sudah Baik', _success, Icons.check_circle_rounded);
    }

    final cond = item.kondisiTemuan ?? '-';
    Color color = _info;
    if (cond == 'Rusak') color = _warning;
    if (cond == 'Hilang') color = _danger;
    return _statusPill(cond, color, Icons.info_rounded);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _statusPill(String text, Color color, IconData icon) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
