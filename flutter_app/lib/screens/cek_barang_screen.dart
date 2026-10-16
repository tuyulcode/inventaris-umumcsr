import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scan_screen.dart';
import 'scan_fast_screen.dart';
import 'cek_list_screen.dart';

const _primary = Color(0xFF4F46E5);
const _primaryDark = Color(0xFF312E81);
const _primarySoft = Color(0xFFEEF2FF);
const _bg = Color(0xFFF5F5FB);
const _textDark = Color(0xFF111827);
const _textGrey = Color(0xFF6B7280);

class CekBarangScreen extends StatelessWidget {
  const CekBarangScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Cek Barang',
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMenuTile(
              context,
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan',
              subtitle: 'Scan QR code & cek kondisi barang',
              onTap: () => _open(context, const ScanScreen()),
            ),
            const SizedBox(height: 12),
            _buildMenuTile(
              context,
              icon: Icons.bolt_rounded,
              title: 'Scan Fast',
              subtitle: 'Pengecekan cepat',
              onTap: () => _open(context, const ScanFastScreen()),
            ),
            const SizedBox(height: 12),
            _buildMenuTile(
              context,
              icon: Icons.checklist_rounded,
              title: 'Cek List',
              subtitle: 'Daftar pengecekan barang',
              onTap: () => _open(context, const CekListScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cek Barang',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pilih mode pengecekan barang.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 12.5, color: _textGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _textGrey, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
