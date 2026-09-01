import 'package:flutter/material.dart';

/// One color preset, values copied directly from the desktop app's
/// renderer/css/themes.css so the two apps genuinely match rather than
/// approximate each other. Desktop always keeps the *content* area light
/// with dark text and only recolors the sidebar/topbar/accent - the phone
/// app mirrors that: Scaffold/card backgrounds stay light, and the accent
/// drives the AppBar, bottom nav, buttons, and links. The "Warm Paper"
/// theme is the one exception where the sidebar itself goes light too,
/// same as on desktop.
class ThemeSpec {
  final String key; // '' = default, matches data-theme="" (no attribute)
  final String label;
  final Color sidebarBg;
  final Color sidebarHover;
  final Color accent; // --blue
  final Color accentDark; // --blue-d
  final Color accentLight; // --blue-l
  final Color contentBg;
  final Color cardBg;
  final Color border;
  final bool lightSidebar; // true only for "Warm Paper"

  const ThemeSpec({
    required this.key,
    required this.label,
    required this.sidebarBg,
    required this.sidebarHover,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.contentBg,
    required this.cardBg,
    required this.border,
    this.lightSidebar = false,
  });
}

class AppThemes {
  // Fixed semantic colors - constant across every theme, same as desktop's
  // :root --green/--red/--amber, which no [data-theme] block overrides.
  static const green = Color(0xFF27AE60);
  static const red = Color(0xFFE74C3C);
  static const amber = Color(0xFFF59E0B);

  static const List<ThemeSpec> all = [
    ThemeSpec(
      key: '', label: 'Dark Navy (Default)',
      sidebarBg: Color(0xFF1A1F33), sidebarHover: Color(0xFF252D4A),
      accent: Color(0xFF4F8EF7), accentDark: Color(0xFF3A7FE5), accentLight: Color(0xFFEBF4FF),
      contentBg: Color(0xFFF0F2F8), cardBg: Colors.white, border: Color(0xFFE2E8F0),
    ),
    ThemeSpec(
      key: 'navy', label: 'Navy & White',
      sidebarBg: Color(0xFF0B1F3A), sidebarHover: Color(0xFF142C4F),
      accent: Color(0xFF2F6FED), accentDark: Color(0xFF1F53C9), accentLight: Color(0xFFE4ECFC),
      contentBg: Color(0xFFF4F7FB), cardBg: Colors.white, border: Color(0xFFDCE4EE),
    ),
    ThemeSpec(
      key: 'goldblack', label: 'Yellow & Black',
      sidebarBg: Color(0xFF0E0E0E), sidebarHover: Color(0xFF1C1C1C),
      accent: Color(0xFFE0AC00), accentDark: Color(0xFFB98900), accentLight: Color(0xFFFCF1CC),
      contentBg: Color(0xFFFAFAF7), cardBg: Colors.white, border: Color(0xFFE7E2CC),
    ),
    ThemeSpec(
      key: 'ocean', label: 'Ocean & Ice',
      sidebarBg: Color(0xFF0A2540), sidebarHover: Color(0xFF123454),
      accent: Color(0xFF16B3AC), accentDark: Color(0xFF0F958F), accentLight: Color(0xFFDFF6F4),
      contentBg: Color(0xFFF2FAFA), cardBg: Colors.white, border: Color(0xFFD6EDEC),
    ),
    ThemeSpec(
      key: 'forest', label: 'Kraft & Pine',
      sidebarBg: Color(0xFF2B2016), sidebarHover: Color(0xFF3A2C1E),
      accent: Color(0xFF4F7942), accentDark: Color(0xFF3E6034), accentLight: Color(0xFFE7F0E2),
      contentBg: Color(0xFFF3ECDF), cardBg: Color(0xFFFBF7EE), border: Color(0xFFDCCBAE),
    ),
    ThemeSpec(
      key: 'purple', label: 'Mahogany & Twine',
      sidebarBg: Color(0xFF331A12), sidebarHover: Color(0xFF45261B),
      accent: Color(0xFFA9432F), accentDark: Color(0xFF8A331F), accentLight: Color(0xFFF3E1D8),
      contentBg: Color(0xFFF6EDE1), cardBg: Color(0xFFFCF6EC), border: Color(0xFFE0CBB0),
    ),
    ThemeSpec(
      key: 'crimson', label: 'Crimson Ribbon',
      sidebarBg: Color(0xFF1C0A0C), sidebarHover: Color(0xFF2C1215),
      accent: Color(0xFFB3213A), accentDark: Color(0xFF8E1A2E), accentLight: Color(0xFFFCE4E4),
      contentBg: Color(0xFFFBEFEF), cardBg: Colors.white, border: Color(0xFFF0D3D3),
    ),
    ThemeSpec(
      key: 'teal', label: 'Emerald & Gold',
      sidebarBg: Color(0xFF14261A), sidebarHover: Color(0xFF1E3826),
      accent: Color(0xFFC79A3B), accentDark: Color(0xFFAB7F27), accentLight: Color(0xFFF6EAC4),
      contentBg: Color(0xFFFBF3DC), cardBg: Color(0xFFFFFBF0), border: Color(0xFFE8D9A9),
    ),
    ThemeSpec(
      key: 'amber', label: 'Onyx & Gold',
      sidebarBg: Color(0xFF15130E), sidebarHover: Color(0xFF221E15),
      accent: Color(0xFFC9A227), accentDark: Color(0xFFA9861A), accentLight: Color(0xFFF3E9C8),
      contentBg: Color(0xFFFAF6EA), cardBg: Color(0xFFFFFDF5), border: Color(0xFFE9DDB8),
    ),
    ThemeSpec(
      key: 'mono', label: 'Noir Confetti',
      sidebarBg: Color(0xFF121212), sidebarHover: Color(0xFF1E1E1E),
      accent: Color(0xFFD32F2F), accentDark: Color(0xFFB22323), accentLight: Color(0xFFFBE3E3),
      contentBg: Color(0xFFF4F4F4), cardBg: Colors.white, border: Color(0xFFE0D6D6),
    ),
    ThemeSpec(
      key: 'slate', label: 'Amber Blaze',
      sidebarBg: Color(0xFF241D06), sidebarHover: Color(0xFF362A0A),
      accent: Color(0xFFE0A526), accentDark: Color(0xFFC08B18), accentLight: Color(0xFFFBEEC2),
      contentBg: Color(0xFFFDF6E1), cardBg: Color(0xFFFFFDF2), border: Color(0xFFEEDCA0),
    ),
    ThemeSpec(
      key: 'indigo', label: 'Ruby Duotone',
      sidebarBg: Color(0xFF170A08), sidebarHover: Color(0xFF2A100C),
      accent: Color(0xFFE8401F), accentDark: Color(0xFFC22F14), accentLight: Color(0xFFFCE0D5),
      contentBg: Color(0xFFFBEEEA), cardBg: Color(0xFFFFF9F6), border: Color(0xFFF0D2C6),
    ),
    ThemeSpec(
      key: 'rose', label: 'Blush Ribbon',
      sidebarBg: Color(0xFF2A1418), sidebarHover: Color(0xFF3B1E24),
      accent: Color(0xFFD5556A), accentDark: Color(0xFFB93F53), accentLight: Color(0xFFFCE7EA),
      contentBg: Color(0xFFFDF3F4), cardBg: Colors.white, border: Color(0xFFF5DEE1),
    ),
    ThemeSpec(
      key: 'light', label: 'Warm Paper',
      sidebarBg: Color(0xFFFAF6EF), sidebarHover: Color(0xFFF0E9DA),
      accent: Color(0xFFC1502E), accentDark: Color(0xFFA43F22), accentLight: Color(0xFFF7E4DA),
      contentBg: Color(0xFFF6F1E7), cardBg: Colors.white, border: Color(0xFFE7DAC4),
      lightSidebar: true,
    ),
  ];

  static ThemeSpec byKey(String key) => all.firstWhere((t) => t.key == key, orElse: () => all.first);

  static ThemeData build(ThemeSpec t) {
    final onSidebar = t.lightSidebar ? const Color(0xFF6B5B47) : const Color(0xFF94A3B8);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: t.accent, brightness: Brightness.light).copyWith(
        primary: t.accent,
        secondary: t.accent,
        surface: t.cardBg,
      ),
      scaffoldBackgroundColor: t.contentBg,
      fontFamily: 'Segoe UI',
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: t.sidebarBg,
        foregroundColor: t.lightSidebar ? const Color(0xFF2B2016) : Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: t.lightSidebar ? const Color(0xFF2B2016) : Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.border, width: 1),
        ),
        color: t.cardBg,
        surfaceTintColor: t.cardBg,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.accent, width: 1.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.accent,
          side: BorderSide(color: t.accent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: t.accent)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: t.accent, foregroundColor: Colors.white),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accent : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accentLight : null),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accent : null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? t.accent : null),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: t.accentLight,
        secondarySelectedColor: t.accentLight,
        labelStyle: TextStyle(color: t.accent),
        side: BorderSide(color: t.border),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? t.accent : t.cardBg),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? Colors.white : t.accent),
          side: WidgetStatePropertyAll(BorderSide(color: t.accent)),
        ),
      ),
      dividerTheme: DividerThemeData(color: t.border, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: null),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.sidebarBg,
        selectedItemColor: t.lightSidebar ? t.accent : Colors.white,
        unselectedItemColor: onSidebar,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent),
      extensions: [AppColors(green: green, red: red, amber: amber, accent: t.accent, accentDark: t.accentDark)],
    );
  }
}

/// Fixed semantic colors + the live theme accent, reachable from any
/// widget via `Theme.of(context).extension<AppColors>()!` without every
/// screen needing to import AppThemes directly.
class AppColors extends ThemeExtension<AppColors> {
  final Color green, red, amber, accent, accentDark;
  const AppColors({required this.green, required this.red, required this.amber, required this.accent, required this.accentDark});

  @override
  AppColors copyWith({Color? green, Color? red, Color? amber, Color? accent, Color? accentDark}) => AppColors(
        green: green ?? this.green,
        red: red ?? this.red,
        amber: amber ?? this.amber,
        accent: accent ?? this.accent,
        accentDark: accentDark ?? this.accentDark,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => this;
}

/// Backwards-compatible static accessors so existing screens that
/// reference AppTheme.blue / AppTheme.red / AppTheme.green keep working
/// unchanged - they resolve to the fixed semantic colors, same value in
/// every theme.
class AppTheme {
  static const green = AppThemes.green;
  static const red = AppThemes.red;
  static const amber = AppThemes.amber;
  static const navy = Color(0xFF1A1F33);
  static const blue = Color(0xFF4F8EF7); // fallback only - prefer Theme.of(context).colorScheme.primary
}
