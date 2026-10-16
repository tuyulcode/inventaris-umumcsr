import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primary = Color(0xFF4F46E5);
const _bg = Color(0xFFF5F5FB);
const _textGrey = Color(0xFF6B7280);
const _textMuted = Color(0xFF9CA3AF);

class ScanFastScreen extends StatelessWidget {
  const ScanFastScreen({super.key});

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 14),
              Text(
                'Scan Fast',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textGrey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fitur ini belum tersedia. Nantikan pembaruannya.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: _textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
