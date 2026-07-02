import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// نظام تصميم «سوقنا» — Souqna Design System.
///
/// ثيمان (داكن/فاتح) مبنيان على نفس الرموز اللونية، مع خط Cairo العربي،
/// وامتداد ثيم [SxColors] تقرأ منه الواجهات كل الألوان بدل الثوابت المبعثرة.
class AppTheme {
  AppTheme._();

  // ---- هوية العلامة ----
  static const Color brand = Color(0xFF14B8A6); // teal
  static const Color brandDark = Color(0xFF0D9488);
  static const Color brandDeep = Color(0xFF115E59);
  static const Color amber = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  /// تدرّج العلامة المستخدم في الترويسات وشاشة الانطلاق.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF2DD4BF)],
  );

  static const String fontFamily = 'Cairo';

  // ================= الثيم الداكن =================
  static ThemeData dark() {
    const sx = SxColors(
      bg: Color(0xFF0B0F14),
      surface: Color(0xFF151B23),
      surfaceHigh: Color(0xFF1D242E),
      tile: Color(0xFF212A36),
      outline: Color(0xFF2B3542),
      textPrimary: Color(0xFFF1F5F9),
      textSecondary: Color(0xFF8FA0B3),
      accent: brand,
      accentSoft: Color(0x2914B8A6),
      onAccent: Color(0xFF04211D),
      warning: amber,
      danger: danger,
      success: success,
      bubbleMine: brandDark,
      onBubbleMine: Colors.white,
      bubbleOther: Color(0xFF232C38),
      onBubbleOther: Color(0xFFE7EDF4),
      shimmerBase: Color(0xFF1A212B),
      shimmerHighlight: Color(0xFF27313E),
    );
    return _build(Brightness.dark, sx);
  }

  // ================= الثيم الفاتح =================
  static ThemeData light() {
    const sx = SxColors(
      bg: Color(0xFFF4F6F8),
      surface: Colors.white,
      surfaceHigh: Color(0xFFEDF1F5),
      tile: Color(0xFFE6EEF0),
      outline: Color(0xFFDDE4EB),
      textPrimary: Color(0xFF10202B),
      textSecondary: Color(0xFF5D7183),
      accent: brandDark,
      accentSoft: Color(0x1A0D9488),
      onAccent: Colors.white,
      warning: Color(0xFFB45309),
      danger: Color(0xFFDC2626),
      success: Color(0xFF15803D),
      bubbleMine: brandDark,
      onBubbleMine: Colors.white,
      bubbleOther: Color(0xFFE9EEF3),
      onBubbleOther: Color(0xFF10202B),
      shimmerBase: Color(0xFFE6EAEF),
      shimmerHighlight: Color(0xFFF5F7FA),
    );
    return _build(Brightness.light, sx);
  }

  static ThemeData _build(Brightness brightness, SxColors sx) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    ).copyWith(
      primary: sx.accent,
      onPrimary: sx.onAccent,
      secondary: sx.accent,
      surface: sx.surface,
      onSurface: sx.textPrimary,
      surfaceContainerHighest: sx.surfaceHigh,
      outline: sx.outline,
      error: sx.danger,
    );

    final textTheme = _textTheme(sx);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: sx.bg,
      textTheme: textTheme,
      extensions: [sx],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: sx.outline, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: sx.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: sx.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: sx.textPrimary,
        ),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sx.surfaceHigh,
        hintStyle: TextStyle(color: sx.textSecondary, fontWeight: FontWeight.w400),
        labelStyle: TextStyle(color: sx.textSecondary),
        prefixIconColor: sx.textSecondary,
        suffixIconColor: sx.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: sx.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: sx.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: sx.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sx.accent,
          foregroundColor: sx.onAccent,
          disabledBackgroundColor: sx.accent.withOpacity(0.45),
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: sx.accent,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: sx.accent.withOpacity(0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sx.accent,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sx.surfaceHigh,
        selectedColor: sx.accent,
        checkmarkColor: sx.onAccent,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: sx.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: sx.onAccent,
        ),
        side: BorderSide(color: sx.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: sx.surface,
        height: 68,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: sx.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? sx.accent
                : sx.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? sx.accent
                : sx.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? sx.surfaceHigh : const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sx.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: sx.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        showDragHandle: true,
        dragHandleColor: sx.outline,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? sx.onAccent : sx.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? sx.accent : sx.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : sx.outline,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? sx.accent
              : sx.textSecondary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: sx.accent),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(fontFamily: fontFamily, color: sx.textPrimary),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: sx.textSecondary,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: sx.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: sx.textSecondary,
        ),
      ),
    );
  }

  static TextTheme _textTheme(SxColors sx) {
    TextStyle s(double size, FontWeight w, {Color? color, double? height}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          color: color ?? sx.textPrimary,
          height: height,
        );
    return TextTheme(
      displaySmall: s(34, FontWeight.w800),
      headlineMedium: s(26, FontWeight.w800),
      headlineSmall: s(22, FontWeight.w700),
      titleLarge: s(19, FontWeight.w700),
      titleMedium: s(16, FontWeight.w700),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400, height: 1.6),
      bodyMedium: s(14, FontWeight.w400, height: 1.55),
      bodySmall: s(12, FontWeight.w400, color: sx.textSecondary),
      labelLarge: s(15, FontWeight.w700),
      labelMedium: s(13, FontWeight.w600),
      labelSmall: s(11, FontWeight.w600, color: sx.textSecondary),
    );
  }
}

/// ألوان «سوقنا» كامتداد ثيم — تتبدّل تلقائياً بين الداكن والفاتح.
@immutable
class SxColors extends ThemeExtension<SxColors> {
  const SxColors({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.tile,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.warning,
    required this.danger,
    required this.success,
    required this.bubbleMine,
    required this.onBubbleMine,
    required this.bubbleOther,
    required this.onBubbleOther,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color tile;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color warning;
  final Color danger;
  final Color success;
  final Color bubbleMine;
  final Color onBubbleMine;
  final Color bubbleOther;
  final Color onBubbleOther;
  final Color shimmerBase;
  final Color shimmerHighlight;

  @override
  SxColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHigh,
    Color? tile,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? warning,
    Color? danger,
    Color? success,
    Color? bubbleMine,
    Color? onBubbleMine,
    Color? bubbleOther,
    Color? onBubbleOther,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return SxColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      tile: tile ?? this.tile,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      bubbleMine: bubbleMine ?? this.bubbleMine,
      onBubbleMine: onBubbleMine ?? this.onBubbleMine,
      bubbleOther: bubbleOther ?? this.bubbleOther,
      onBubbleOther: onBubbleOther ?? this.onBubbleOther,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  SxColors lerp(ThemeExtension<SxColors>? other, double t) {
    if (other is! SxColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SxColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      tile: l(tile, other.tile),
      outline: l(outline, other.outline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      success: l(success, other.success),
      bubbleMine: l(bubbleMine, other.bubbleMine),
      onBubbleMine: l(onBubbleMine, other.onBubbleMine),
      bubbleOther: l(bubbleOther, other.bubbleOther),
      onBubbleOther: l(onBubbleOther, other.onBubbleOther),
      shimmerBase: l(shimmerBase, other.shimmerBase),
      shimmerHighlight: l(shimmerHighlight, other.shimmerHighlight),
    );
  }
}

/// وصول مختصر لألوان سوقنا من أي BuildContext:  `context.sx.accent`
extension SxThemeContext on BuildContext {
  SxColors get sx => Theme.of(this).extension<SxColors>()!;
}
