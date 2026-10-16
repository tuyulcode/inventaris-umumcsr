import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

const _primary = Color(0xFF4F46E5);
const _primaryDark = Color(0xFF312E81);
const _primarySoft = Color(0xFFEEF2FF);
const _bg = Color(0xFFF5F5FB);
const _ink = Color(0xFF111827);
const _inkSoft = Color(0xFF6B7280);
const _inkFaint = Color(0xFF9CA3AF);
const _line = Color(0xFFECEEF3);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFEF4444);

class ScanFastScreen extends StatefulWidget {
  const ScanFastScreen({super.key});

  @override
  State<ScanFastScreen> createState() => _ScanFastScreenState();
}

class _ScanFastScreenState extends State<ScanFastScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  bool _cameraActive = false;
  MobileScannerController? _scannerController;

  bool _isSearching = false;
  bool _isSubmitting = false;

  String? _periodeInfo;
  bool _hasPeriode = true;

  final List<Map<String, String>> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadPeriodeInfo();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

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

  void _toggleCamera() {
    setState(() {
      if (_cameraActive) {
        _scannerController?.stop();
        _scannerController?.dispose();
        _scannerController = null;
        _cameraActive = false;
      } else {
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        );
        _cameraActive = true;
      }
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _scannerController?.stop();
    setState(() => _cameraActive = false);
    _codeController.text = code;
    _processCode(code);
  }

  Future<void> _processCode(String code) async {
    final id = int.tryParse(code.trim());
    if (id == null || id <= 0) {
      _showSnack('ID Barang tidak valid!', _danger, Icons.error_rounded);
      _resetInput();
      return;
    }

    setState(() => _isSearching = true);
    final result = await ApiService.getBarang(id.toString());
    if (!mounted) return;
    setState(() => _isSearching = false);

    if (result['success'] != true) {
      _showSnack(result['message'] ?? 'Barang tidak ditemukan!', _danger, Icons.search_off_rounded);
      _resetInput();
      return;
    }

    final barang = result['data'];
    final confirmed = await _showConfirmDialog(barang);
    if (confirmed == true) {
      await _submit(barang.id, barang.namaBarang, barang.namaUnit, barang.namaRuang);
    } else {
      _resetInput();
    }
  }

  Future<bool?> _showConfirmDialog(dynamic barang) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Konfirmasi Mode Fast',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('ID / Kode Barang', barang.formattedCode),
                  const SizedBox(height: 8),
                  _detailRow('Nama Barang', barang.namaBarang),
                  const SizedBox(height: 8),
                  _detailRow('Lokasi', '${barang.namaUnit} \u2192 ${barang.namaRuang}'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 13, color: _inkSoft, height: 1.4),
                children: const [
                  TextSpan(text: 'Simpan barang ini dengan status '),
                  TextSpan(
                    text: 'Baik',
                    style: TextStyle(fontWeight: FontWeight.w800, color: _success),
                  ),
                  TextSpan(text: '?'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: _danger, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ya, Simpan!', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: _inkFaint)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink),
        ),
      ],
    );
  }

  Future<void> _submit(int idBarang, String nama, String unit, String ruang) async {
    setState(() => _isSubmitting = true);
    final result = await ApiService.submitPengecekan(
      idBarang: idBarang,
      kondisiTemuan: 'Baik',
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      HapticFeedback.mediumImpact();
      setState(() {
        _recent.insert(0, {'nama': nama, 'unit': unit, 'ruang': ruang});
        if (_recent.length > 20) _recent.removeLast();
      });
      _showSnack('"$nama" tersimpan dengan kondisi Baik.', _success, Icons.check_circle_rounded);
      _resetInput();
    } else {
      _showSnack(result['message'] ?? 'Gagal menyimpan', _danger, Icons.error_rounded);
      _resetInput();
    }
  }

  void _resetInput() {
    _codeController.clear();
    if (mounted) _codeFocus.requestFocus();
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

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Scan Fast',
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
            _buildScanCard(),
            const SizedBox(height: 16),
            _buildNote(),
            if (_recent.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildRecentHeader(),
              const SizedBox(height: 10),
              ..._recent.map(_buildRecentItem),
            ],
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

  Widget _buildScanCard() {
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
          Text(
            'Scan QR Code / Input ID',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Barang otomatis berstatus Baik.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: _inkFaint),
          ),
          const SizedBox(height: 16),

          if (_cameraActive) ...[
            _buildScannerViewport(),
            const SizedBox(height: 14),
          ],

          ElevatedButton.icon(
            onPressed: _toggleCamera,
            icon: Icon(
              _cameraActive ? Icons.stop_rounded : Icons.camera_alt_rounded,
              size: 20,
            ),
            label: Text(
              _cameraActive ? 'Matikan Kamera Scanner' : 'Mulai Kamera Scanner',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cameraActive ? _danger : _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Expanded(child: Divider(color: _line, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ATAU',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _inkFaint,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _line, thickness: 1)),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  enabled: !_isSubmitting,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _ink,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.tag_rounded, size: 19, color: _inkFaint),
                    hintText: 'Masukkan ID / Barcode',
                    hintStyle: GoogleFonts.inter(
                      color: _inkFaint,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: _bg,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                  ),
                  onSubmitted: (v) => _processCode(v),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  onPressed: (_isSearching || _isSubmitting)
                      ? null
                      : () => _processCode(_codeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.search_rounded, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewport() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onBarcodeDetected,
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 200,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNote() {
    return Row(
      children: [
        const Icon(Icons.bolt_rounded, color: _warning, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Mode Fast: barang yang di-scan akan otomatis berstatus Baik.',
            style: GoogleFonts.inter(fontSize: 12.5, color: _inkSoft),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHeader() {
    return Text(
      'Baru Saja Dicek',
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
    );
  }

  Widget _buildRecentItem(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: _primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'] ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['unit']} \u2192 ${item['ruang']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11.5, color: _inkFaint),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: _success, size: 20),
        ],
      ),
    );
  }
}
