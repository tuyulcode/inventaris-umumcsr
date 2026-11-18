import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/barang.dart';
import '../models/ruang.dart';

class _C {
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF4338CA);
  static const primaryLight = Color(0xFF818CF8);
  static const primarySoft = Color(0xFFEEF2FF);
  static const primarySoftBorder = Color(0xFFDDE3FC);

  static const bg = Color(0xFFF5F5FB);
  static const surface = Colors.white;

  static const ink = Color(0xFF111827);
  static const inkSoft = Color(0xFF4B5563);
  static const inkFaint = Color(0xFF9CA3AF);
  static const line = Color(0xFFECEEF3);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _SuccessDialogContent extends StatefulWidget {
  final String message;
  final String title;
  const _SuccessDialogContent({
    required this.message,
    this.title = 'Berhasil!',
  });

  @override
  State<_SuccessDialogContent> createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<_SuccessDialogContent>
    with TickerProviderStateMixin {
  late final AnimationController _circleController;
  late final AnimationController _checkController;
  late final AnimationController _textController;
  late final AnimationController _progressController;

  late final Animation<double> _circleScale;
  late final Animation<double> _checkScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _circleScale = CurvedAnimation(
      parent: _circleController,
      curve: Curves.elasticOut,
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _circleController.forward();
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _checkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 380), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _C.success.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circle dengan glow + gradient
              ScaleTransition(
                scale: _circleScale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), _C.success],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.success.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _checkScale,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: _C.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          height: 1.5,
                          color: _C.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Progress bar tipis penanda auto-close
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 4,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _progressController.value,
                      backgroundColor: _C.line,
                      valueColor: const AlwaysStoppedAnimation(_C.success),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanScreenState extends State<ScanScreen> {
  final _codeController = TextEditingController();
  final _catatanController = TextEditingController();
  final _namaBarangController = TextEditingController();
  final _jumlahController = TextEditingController(text: '1');
  final _scrollController = ScrollController();
  final _registerCardKey = GlobalKey();

  bool _cameraActive = false;
  MobileScannerController? _scannerController;

  Barang? _selectedBarang;
  String _kondisiTemuan = 'Baik';
  File? _fotoBukti;
  bool _isSearching = false;
  bool _isSubmitting = false;

  bool _alreadyChecked = false;
  String _checkInfo = '';

  String _notFoundCode = '';
  bool _isRegisterPromptOpen = false;

  bool _showRegisterForm = false;
  bool _isLoadingMaster = false;
  bool _isRegistering = false;
  List<Map<String, dynamic>> _masterUnits = [];
  List<Map<String, dynamic>> _masterJenis = [];
  List<Map<String, dynamic>> _masterKategori = [];
  List<Map<String, dynamic>> _masterMerk = [];
  List<Ruang> _registerRooms = [];
  int? _regUnitId;
  int? _regRuangId;
  int? _regJenisId;
  int? _regKategoriId;
  int? _regMerkId;
  String _regKondisi = 'Baik';
  DateTime? _regTglPembelian;
  File? _regFoto;

  String? _periodeInfo;
  bool _hasPeriode = true;

  @override
  void initState() {
    super.initState();
    _loadPeriodeInfo();
  }

  Future<void> _loadPeriodeInfo() async {
    final result = await ApiService.getDashboard();
    if (mounted && result['success'] == true) {
      final data = result['data'];
      final periode = data['periode_aktif'];
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
  }

  @override
  void dispose() {
    _codeController.dispose();
    _catatanController.dispose();
    _namaBarangController.dispose();
    _jumlahController.dispose();
    _scrollController.dispose();
    _scannerController?.dispose();
    super.dispose();
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
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _scannerController?.stop();
        setState(() => _cameraActive = false);
        _codeController.text = code;
        _searchBarang(code);
      }
    }
  }

  Future<void> _searchBarang(String code) async {
    if (code.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _selectedBarang = null;
      _alreadyChecked = false;
      _showRegisterForm = false;
    });

    final result = await ApiService.getBarang(code.trim());
    if (!mounted) return;

    if (result['success'] == true) {
      final barang = result['data'] as Barang;
      setState(() {
        _selectedBarang = barang;
        _isSearching = false;
        _kondisiTemuan = 'Baik';
        _fotoBukti = null;
        _catatanController.clear();
        _showRegisterForm = false;
      });

      _scrollToBottomAfterLayout();
      _checkBarangStatus(barang.id);
      return;
    }

    setState(() => _isSearching = false);

    if (result['is_inactive'] == true) {
      _showSnack(
        result['message'] ?? 'Barang sudah dikeluarkan dari inventaris.',
        _C.danger,
        Icons.block_rounded,
      );
      return;
    }

    if (result['can_register'] != true) {
      _showSnack(
        result['message'] ?? 'Gagal mengambil data barang.',
        _C.danger,
        Icons.error_rounded,
      );
      return;
    }

    final labelCode = code.trim();
    setState(() => _notFoundCode = labelCode);

    final shouldRegister = await _showRegisterPrompt(labelCode);
    if (!mounted) return;

    if (shouldRegister) {
      await _openRegisterForm();
    } else {
      _cancelRegister();
    }
  }

  void _scrollToBottomAfterLayout() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToRegisterForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _registerCardKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        );
      }
    });
  }

  Future<void> _checkBarangStatus(int barangId) async {
    final result = await ApiService.checkStatus(barangId);
    if (mounted && result['already_checked'] == true) {
      setState(() {
        _alreadyChecked = true;
        _checkInfo =
            'Barang ini sudah pernah dicek oleh ${result['petugas']} pada ${result['tanggal']} dengan temuan ${result['kondisi']}.';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _chooseImage();
    if (picked != null && mounted) {
      setState(() => _fotoBukti = picked);
    }
  }

  Future<void> _pickRegisterPhoto() async {
    final picked = await _chooseImage();
    if (picked != null && mounted) {
      setState(() => _regFoto = picked);
    }
  }

  Future<File?> _chooseImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: _C.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Sumber Foto',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sheetOption(
                  ctx: ctx,
                  icon: Icons.photo_camera_rounded,
                  title: 'Kamera',
                  subtitle: 'Ambil foto baru',
                  value: ImageSource.camera,
                ),
                const SizedBox(height: 10),
                _sheetOption(
                  ctx: ctx,
                  icon: Icons.image_rounded,
                  title: 'Galeri',
                  subtitle: 'Pilih dari galeri',
                  value: ImageSource.gallery,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (source == null) return null;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 80,
    );
    return picked != null ? File(picked.path) : null;
  }

  Widget _sheetOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required ImageSource value,
  }) {
    return Material(
      color: _C.primarySoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(ctx, value),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _C.primary, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _C.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _C.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _C.inkFaint),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _asOptionList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return [];
  }

  int? _optionId(Map<String, dynamic> item) {
    final value = item['id'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _optionName(Map<String, dynamic> item) {
    return (item['nama'] ?? item['nama_unit'] ?? item['nama_ruang'] ?? '-')
        .toString();
  }

  void _resetRegisterState() {
    _namaBarangController.clear();
    _jumlahController.text = '1';
    _masterUnits = [];
    _masterJenis = [];
    _masterKategori = [];
    _masterMerk = [];
    _registerRooms = [];
    _regUnitId = null;
    _regRuangId = null;
    _regJenisId = null;
    _regKategoriId = null;
    _regMerkId = null;
    _regKondisi = 'Baik';
    _regTglPembelian = null;
    _regFoto = null;
    _isLoadingMaster = false;
    _isRegistering = false;
  }

  Future<bool> _showRegisterPrompt(String code) async {
    if (_isRegisterPromptOpen) return false;
    _isRegisterPromptOpen = true;

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: _C.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: _C.warning,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Label Belum Terdaftar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.primarySoftBorder),
                  ),
                  child: Text(
                    'Kode label: $code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Label ini masih tersedia dan belum digunakan barang lain. Daftarkan label ini sebagai barang baru?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.45,
                    color: _C.inkSoft,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.app_registration_rounded, size: 19),
                    label: Text(
                      'Register Barang',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.inkSoft,
                      side: const BorderSide(color: _C.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return result == true;
    } finally {
      _isRegisterPromptOpen = false;
    }
  }

  Future<void> _openRegisterForm() async {
    setState(() {
      _resetRegisterState();
      _showRegisterForm = true;
      _isLoadingMaster = true;
    });

    final result = await ApiService.getMasterData();
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() {
        _isLoadingMaster = false;
        _showRegisterForm = false;
        _notFoundCode = '';
      });
      _showSnack(
        result['message'] ?? 'Gagal memuat data master.',
        _C.danger,
        Icons.error_rounded,
      );
      return;
    }

    final data = (result['data'] as Map).cast<String, dynamic>();
    final units = _asOptionList(data['unit']);
    int? defaultUnitId;
    final defaultIndex = units.indexWhere(
      (u) => _optionName(u).trim().toUpperCase() == 'RUMAH JABATAN',
    );
    if (defaultIndex >= 0) {
      defaultUnitId = _optionId(units[defaultIndex]);
    }

    setState(() {
      _masterUnits = units;
      _masterJenis = _asOptionList(data['jenis']);
      _masterKategori = _asOptionList(data['kategori']);
      _masterMerk = _asOptionList(data['merk']);
      _regUnitId = defaultUnitId;
      _registerRooms = [];
      _regRuangId = null;
      _isLoadingMaster = false;
    });

    if (defaultUnitId != null) {
      await _loadRegisterRooms(defaultUnitId);
    }
    _scrollToRegisterForm();
  }

  Future<void> _loadRegisterRooms(int unitId) async {
    setState(() {
      _registerRooms = [];
      _regRuangId = null;
    });

    final result = await ApiService.getRuang(unitId);
    if (!mounted || _regUnitId != unitId || result['success'] != true) return;

    setState(() {
      _registerRooms = (result['data'] as List<Ruang>);
    });
  }

  void _cancelRegister() {
    FocusScope.of(context).unfocus();
    setState(() {
      _resetRegisterState();
      _showRegisterForm = false;
      _notFoundCode = '';
      _codeController.clear();
    });
  }

  Future<void> _pickRegistrationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _regTglPembelian ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _regTglPembelian = picked);
    }
  }

  Future<void> _submitRegistration() async {
    final kode = _notFoundCode.trim();
    final parsedCode = int.tryParse(kode);
    if (!RegExp(r'^\d+$').hasMatch(kode) ||
        parsedCode == null ||
        parsedCode <= 0) {
      _showSnack('Kode label tidak valid.', _C.danger, Icons.error_rounded);
      return;
    }
    if (_namaBarangController.text.trim().isEmpty) {
      _showSnack('Nama barang wajib diisi.', _C.danger, Icons.warning_rounded);
      return;
    }
    if (_regUnitId == null) {
      _showSnack('Unit wajib dipilih.', _C.danger, Icons.warning_rounded);
      return;
    }
    if (_regRuangId == null) {
      _showSnack('Ruangan wajib dipilih.', _C.danger, Icons.warning_rounded);
      return;
    }
    if (_regJenisId == null) {
      _showSnack('Jenis wajib dipilih.', _C.danger, Icons.warning_rounded);
      return;
    }
    if (_regKategoriId == null) {
      _showSnack('Kategori wajib dipilih.', _C.danger, Icons.warning_rounded);
      return;
    }
    if (_regMerkId == null) {
      _showSnack('Merk wajib dipilih.', _C.danger, Icons.warning_rounded);
      return;
    }

    final jumlah = int.tryParse(_jumlahController.text.trim()) ?? 0;
    if (jumlah < 1) {
      _showSnack('Jumlah barang minimal 1.', _C.danger, Icons.warning_rounded);
      return;
    }
    if (_regTglPembelian == null) {
      _showSnack(
        'Tanggal pembelian wajib diisi.',
        _C.danger,
        Icons.warning_rounded,
      );
      return;
    }
    if (_regKondisi == 'Rusak' && _regFoto == null) {
      _showSnack(
        'Foto barang wajib dilampirkan jika kondisi Rusak!',
        _C.danger,
        Icons.warning_rounded,
      );
      return;
    }

    setState(() => _isRegistering = true);

    final result = await ApiService.registerBarang(
      labelCode: kode,
      namaBarang: _namaBarangController.text.trim(),
      idUnit: _regUnitId!,
      idRuang: _regRuangId!,
      idJenis: _regJenisId!,
      idKategori: _regKategoriId!,
      idMerk: _regMerkId!,
      jumlah: jumlah,
      kondisi: _regKondisi,
      tglPembelian: DateFormat('yyyy-MM-dd').format(_regTglPembelian!),
      foto: _regFoto,
    );

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (result['success'] == true) {
      _showSnack(
        result['message'] ?? 'Registrasi label berhasil.',
        _C.success,
        Icons.check_circle_rounded,
      );
      setState(() {
        _showRegisterForm = false;
        _resetRegisterState();
      });
      await _searchBarang(kode);
    } else {
      _showSnack(
        result['message'] ?? 'Gagal mendaftarkan label.',
        _C.danger,
        Icons.error_rounded,
      );
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
              child: Text(
                msg,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
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

  Future<void> _showSuccessDialog(String message) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (ctx, anim1, anim2) =>
          _SuccessDialogContent(message: message),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * anim.value,
            sigmaY: 6 * anim.value,
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _submitPengecekan() async {
    if (_selectedBarang == null) return;

    if (_kondisiTemuan == 'Rusak' && _fotoBukti == null) {
      _showSnack(
        'Foto bukti wajib dilampirkan untuk kondisi Rusak!',
        _C.danger,
        Icons.warning_rounded,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ApiService.submitPengecekan(
      idBarang: _selectedBarang!.id,
      kondisiTemuan: _kondisiTemuan,
      catatan: _catatanController.text.trim(),
      fotoBukti: _kondisiTemuan == 'Rusak' ? _fotoBukti : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      await _showSuccessDialog(
        result['message'] ?? 'Pengecekan berhasil dikirim.',
      );
      if (!mounted) return;
      setState(() {
        _selectedBarang = null;
        _fotoBukti = null;
        _catatanController.clear();
        _codeController.clear();
        _alreadyChecked = false;
        _kondisiTemuan = 'Baik';
      });
    } else {
      _showSnack(
        result['message'] ?? 'Gagal mengirim',
        _C.danger,
        Icons.error_rounded,
      );
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          'Scan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_periodeInfo != null) _buildPeriodeBanner(),
          if (!_hasPeriode) _buildNoPeriodeBanner(),

          const SizedBox(height: 16),

          _buildScannerSection(),

          if (_isSearching) ...[
            const SizedBox(height: 24),
            const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _C.primary,
                ),
              ),
            ),
          ],

          if (_selectedBarang != null) ...[
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildDetailCard(key: ValueKey(_selectedBarang!.id)),
            ),
          ] else if (_showRegisterForm) ...[
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildRegisterCard(key: const ValueKey('register_form')),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  Periode banners
  // ------------------------------------------------------------

  Widget _buildPeriodeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.primary, _C.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.28),
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERIODE AKTIF',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _periodeInfo!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
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
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE4A8)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: _C.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tidak ada periode pengecekan aktif saat ini.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  Scanner section
  // ------------------------------------------------------------

  Widget _buildScannerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.line),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_cameraActive && _scannerController != null) ...[
            _buildScannerViewport(),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.primaryLight, _C.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Identifikasi Aset',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gunakan kamera atau masukkan kode manual',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: _C.inkFaint,
              ),
            ),
            const SizedBox(height: 20),
          ],

          _primaryButton(
            onTap: _toggleCamera,
            active: _cameraActive,
            icon: _cameraActive ? Icons.stop_rounded : Icons.camera_alt_rounded,
            label: _cameraActive
                ? 'Matikan Kamera Scanner'
                : 'Mulai Kamera Scanner',
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Expanded(child: Divider(color: _C.line, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ATAU',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _C.inkFaint,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _C.line, thickness: 1)),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _C.ink,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.tag_rounded,
                      size: 19,
                      color: _C.inkFaint,
                    ),
                    hintText: 'Contoh: 00005 atau 5',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: _C.inkFaint,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: _C.bg,
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
                      borderSide: const BorderSide(
                        color: _C.primary,
                        width: 1.6,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (v) => _searchBarang(v),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  onPressed: _isSearching
                      ? null
                      : () => _searchBarang(_codeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.search_rounded, size: 22),
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _C.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mencari barcode…',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol utama gradient (indigo/ungu), dipakai untuk mulai kamera & kirim laporan.
  Widget _primaryButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    bool active = false,
    bool loading = false,
  }) {
    final colors = active
        ? const [Color(0xFFFB7185), _C.danger]
        : const [_C.primaryLight, _C.primary];
    final shadowColor = active ? _C.danger : _C.primary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onTap == null ? 0.55 : 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  //  Detail card
  // ------------------------------------------------------------

  Widget _buildDetailCard({Key? key}) {
    final barang = _selectedBarang!;
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.line),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header gradient ungu (dulu abu gelap)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.primaryDark, _C.primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barang.namaBarang,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            color: Colors.white.withValues(alpha: 0.65),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '# ${barang.formattedCode}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      if (barang.foto != null && barang.foto!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 130,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: ApiConfig.barangImageUrl(barang.foto!),
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Container(
                                color: Colors.white,
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _C.primary,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 36,
                                  color: _C.inkFaint,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _infoItem('KATEGORI', barang.namaKategori),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _infoItem('MERK', barang.namaMerk)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _infoItemBadge(
                              'KONDISI TERAKHIR',
                              barang.kondisi,
                              _kondisiColor(barang.kondisi),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoItemBadge(
                              'STATUS AKTIF',
                              barang.statusAktif == 'aktif'
                                  ? 'Aktif'
                                  : 'Nonaktif',
                              barang.statusAktif == 'aktif'
                                  ? _C.success
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _infoItemWithIcon(
                        'LOKASI PENEMPATAN',
                        '${barang.namaUnit} → ${barang.namaRuang}',
                        Icons.location_on_rounded,
                        _C.primary,
                      ),
                    ],
                  ),
                ),

                if (_alreadyChecked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: _C.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.primarySoftBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: _C.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _checkInfo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _C.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                Text(
                  'Kondisi Fisik Saat Ini *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildKondisiButton(
                      'Baik',
                      Icons.check_circle_rounded,
                      _C.success,
                    ),
                    const SizedBox(width: 10),
                    _buildKondisiButton(
                      'Rusak',
                      Icons.build_rounded,
                      _C.warning,
                    ),
                    const SizedBox(width: 10),
                    _buildKondisiButton(
                      'Hilang',
                      Icons.cancel_rounded,
                      _C.danger,
                    ),
                  ],
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _kondisiTemuan == 'Rusak'
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lampirkan Foto Bukti *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _C.danger,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_fotoBukti != null)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        _fotoBukti!,
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _fotoBukti = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.55,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_fotoBukti != null) const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _fotoBukti != null
                                      ? 'Ganti Foto'
                                      : 'Ambil Foto / Pilih File',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _C.primary,
                                  side: const BorderSide(color: _C.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  minimumSize: const Size(double.infinity, 0),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Melampirkan foto bukti kondisi fisik wajib untuk temuan barang rusak.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: _C.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                Text(
                  'Catatan Tambahan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _catatanController,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _C.ink,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Tuliskan keterangan detail kondisi fisik barang jika diperlukan...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: _C.inkFaint,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: _C.bg,
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
                      borderSide: const BorderSide(
                        color: _C.primary,
                        width: 1.6,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),

                const SizedBox(height: 22),

                _primaryButton(
                  onTap: _isSubmitting ? null : _submitPengecekan,
                  icon: Icons.send_rounded,
                  label: _isSubmitting ? 'Memproses...' : 'Kirim Laporan',
                  loading: _isSubmitting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  Form registrasi label baru
  // ------------------------------------------------------------
  Widget _buildRegisterCard({Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.line),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(key: _registerCardKey, height: 0),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.primaryDark, _C.primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.app_registration_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registrasi Label Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kode label: ${_notFoundCode.isEmpty ? '-' : _notFoundCode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingMaster
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: _C.primary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _C.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.primarySoftBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Label ${_notFoundCode.isEmpty ? '-' : _notFoundCode} belum terdaftar. Isi data barang di bawah ini.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _C.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lokasi default label: RUMAH JABATAN → -',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: _C.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _regFieldLabel('Nama Barang', required: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _namaBarangController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: _C.ink,
                        ),
                        decoration: _regInputDecoration('Masukkan nama barang'),
                      ),
                      const SizedBox(height: 14),
                      _regFieldLabel('Unit', required: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        key: ValueKey('reg_unit_$_regUnitId'),
                        initialValue: _regUnitId,
                        isExpanded: true,
                        decoration: _regInputDecoration('Pilih unit'),
                        hint: Text(
                          'Pilih unit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: _C.inkFaint,
                          ),
                        ),
                        items: _masterUnits
                            .map((u) {
                              final id = _optionId(u);
                              if (id == null) return null;
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  _optionName(u),
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: _C.ink,
                                  ),
                                ),
                              );
                            })
                            .whereType<DropdownMenuItem<int>>()
                            .toList(),
                        onChanged: (value) {
                          setState(() => _regUnitId = value);
                          if (value != null) _loadRegisterRooms(value);
                        },
                      ),
                      const SizedBox(height: 14),
                      _regFieldLabel('Ruangan', required: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        key: ValueKey(
                          'reg_ruang_${_regUnitId ?? 0}_${_regRuangId ?? 0}',
                        ),
                        initialValue: _regRuangId,
                        isExpanded: true,
                        decoration: _regInputDecoration('Pilih ruangan'),
                        hint: Text(
                          _regUnitId == null
                              ? 'Pilih unit terlebih dahulu'
                              : (_registerRooms.isEmpty
                                    ? 'Tidak ada ruangan'
                                    : 'Pilih ruangan'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: _C.inkFaint,
                          ),
                        ),
                        items: _registerRooms
                            .map(
                              (r) => DropdownMenuItem<int>(
                                value: r.id,
                                child: Text(
                                  r.namaRuang,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: _C.ink,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _regUnitId == null
                            ? null
                            : (value) => setState(() => _regRuangId = value),
                      ),
                      const SizedBox(height: 14),
                      _regFieldLabel('Jenis', required: true),
                      const SizedBox(height: 6),
                      _buildMasterDropdown(
                        keyName: 'reg_jenis',
                        value: _regJenisId,
                        items: _masterJenis,
                        hint: 'Pilih jenis',
                        onChanged: (value) =>
                            setState(() => _regJenisId = value),
                      ),
                      const SizedBox(height: 14),
                      _regFieldLabel('Kategori', required: true),
                      const SizedBox(height: 6),
                      _buildMasterDropdown(
                        keyName: 'reg_kategori',
                        value: _regKategoriId,
                        items: _masterKategori,
                        hint: 'Pilih kategori',
                        onChanged: (value) =>
                            setState(() => _regKategoriId = value),
                      ),
                      const SizedBox(height: 14),
                      _regFieldLabel('Merk', required: true),
                      const SizedBox(height: 6),
                      _buildMasterDropdown(
                        keyName: 'reg_merk',
                        value: _regMerkId,
                        items: _masterMerk,
                        hint: 'Pilih merk',
                        onChanged: (value) =>
                            setState(() => _regMerkId = value),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _regFieldLabel('Jumlah', required: true),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _jumlahController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: _C.ink,
                                  ),
                                  decoration: _regInputDecoration('1'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _regFieldLabel(
                                  'Tanggal Pembelian',
                                  required: true,
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _pickRegistrationDate,
                                  child: InputDecorator(
                                    decoration: _regInputDecoration(
                                      'Pilih tanggal pembelian',
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 18,
                                          color: _C.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _regTglPembelian == null
                                                ? 'Pilih tanggal'
                                                : DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(_regTglPembelian!),
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              color: _regTglPembelian == null
                                                  ? _C.inkFaint
                                                  : _C.ink,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _regFieldLabel('Kondisi Barang', required: true),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRegisterKondisiButton(
                            'Baik',
                            Icons.check_circle_rounded,
                            _C.success,
                          ),
                          const SizedBox(width: 8),
                          _buildRegisterKondisiButton(
                            'Rusak',
                            Icons.build_rounded,
                            _C.warning,
                          ),
                          const SizedBox(width: 8),
                          _buildRegisterKondisiButton(
                            'Hilang',
                            Icons.cancel_rounded,
                            _C.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _regFieldLabel(
                        _regKondisi == 'Rusak'
                            ? 'Foto Barang'
                            : 'Foto Barang (Opsional)',
                        required: _regKondisi == 'Rusak',
                      ),
                      const SizedBox(height: 8),
                      if (_regFoto != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _regFoto!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _regFoto = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: _pickRegisterPhoto,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: Text(
                          _regFoto != null
                              ? 'Ganti Foto Barang'
                              : 'Ambil Foto / Pilih File',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.primary,
                          side: const BorderSide(color: _C.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                      ),
                      if (_regKondisi == 'Rusak') ...[
                        const SizedBox(height: 6),
                        Text(
                          'Foto barang wajib dilampirkan untuk kondisi Rusak.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _C.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _isRegistering
                                  ? null
                                  : _submitRegistration,
                              icon: _isRegistering
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 19),
                              label: Text(
                                _isRegistering
                                    ? 'Menyimpan...'
                                    : 'Simpan Registrasi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isRegistering
                                  ? null
                                  : _cancelRegister,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _C.inkSoft,
                                side: const BorderSide(color: _C.line),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE4A8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: _C.warning,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Barang dengan kondisi Rusak memerlukan foto dan persetujuan admin sebelum dapat di cek',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  height: 1.45,
                                  color: const Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterDropdown({
    required String keyName,
    required int? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey('${keyName}_${value ?? 0}'),
      initialValue: value,
      isExpanded: true,
      decoration: _regInputDecoration(hint),
      hint: Text(
        items.isEmpty ? 'Belum ada data master' : hint,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: _C.inkFaint),
      ),
      items: items
          .map((item) {
            final id = _optionId(item);
            if (id == null) return null;
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                _optionName(item),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: _C.ink,
                ),
              ),
            );
          })
          .whereType<DropdownMenuItem<int>>()
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }

  Widget _buildRegisterKondisiButton(String label, IconData icon, Color color) {
    final isSelected = _regKondisi == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _regKondisi = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.10) : _C.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? color : _C.inkFaint),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : _C.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _regFieldLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _C.ink,
        ),
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.danger,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _regInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: _C.inkFaint,
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: _C.bg,
      isDense: true,
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
        borderSide: const BorderSide(color: _C.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // ------------------------------------------------------------
  //  Kondisi fisik card button
  // ------------------------------------------------------------

  Widget _buildKondisiButton(String label, IconData icon, Color color) {
    final isSelected = _kondisiTemuan == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _kondisiTemuan = label;
            if (label != 'Rusak') _fotoBukti = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.10) : _C.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: isSelected ? color : _C.inkFaint),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : _C.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _kondisiColor(String kondisi) {
    switch (kondisi) {
      case 'Baik':
        return _C.success;
      case 'Rusak':
        return _C.warning;
      case 'Hilang':
        return _C.danger;
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ------------------------------------------------------------
  //  Info helpers
  // ------------------------------------------------------------

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _C.inkFaint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _C.ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _infoItemBadge(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _C.inkFaint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoItemWithIcon(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _C.inkFaint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
