import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrutalistPalette {
  static const bg = Color(0xFF000000);
  static const panel = Color(0xFF111111);
  static const border = Color(0xFF333333);
  static const muted = Color(0xFF888888);
  static const accent = Color(0xFF6366F1);
}

class BrutalistScaffold extends StatelessWidget {
  const BrutalistScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalistPalette.bg,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ScanlinePainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class BrutalistHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrutalistHeader({
    super.key,
    required this.title,
    this.bottom,
    this.leading,
    this.centerTitle = true,
  });

  final String title;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight((bottom?.preferredSize.height ?? 0) + 56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: BrutalistPalette.bg,
      elevation: 0,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: GoogleFonts.spaceMono(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: leading,
      bottom: bottom,
      shape: const Border(bottom: BorderSide(color: BrutalistPalette.border)),
    );
  }
}

InputDecoration brutalistInputDecoration({
  String? labelText,
  String? hintText,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: BrutalistPalette.border),
  );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: GoogleFonts.spaceMono(color: BrutalistPalette.muted),
    hintStyle: GoogleFonts.spaceMono(color: BrutalistPalette.muted),
    filled: true,
    fillColor: BrutalistPalette.panel,
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: BrutalistPalette.accent, width: 1.5),
    ),
  );
}

ButtonStyle brutalistPrimaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: BrutalistPalette.accent,
    foregroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    textStyle: GoogleFonts.spaceMono(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    ),
  );
}

ButtonStyle brutalistOutlineButtonStyle({bool active = false}) {
  return OutlinedButton.styleFrom(
    foregroundColor: active ? Colors.white : BrutalistPalette.muted,
    backgroundColor: active ? BrutalistPalette.accent : Colors.transparent,
    side: BorderSide(
      color: active ? BrutalistPalette.accent : BrutalistPalette.border,
    ),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    textStyle: GoogleFonts.spaceMono(
      letterSpacing: 1.0,
      fontWeight: FontWeight.w700,
    ),
  );
}

class BrutalistPanel extends StatelessWidget {
  const BrutalistPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BrutalistPalette.panel,
        border: Border.all(color: BrutalistPalette.border),
      ),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = BrutalistPalette.accent.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.11)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
