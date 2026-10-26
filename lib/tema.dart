import 'package:flutter/material.dart';

enum AppTheme { dark, light }

enum AppAccent {
  gold('Altın', Color(0xFFD4AF37)),
  ocean('Okyanus', Color(0xFF4387A8)),
  jade('Yeşim', Color(0xFF378C73)),
  plum('Erik', Color(0xFF9668A8)),
  terracotta('Kiremit', Color(0xFFC97858));

  const AppAccent(this.label, this.color);

  final String label;
  final Color color;
}

ThemeData buildAppTheme(
  AppTheme appTheme, {
  AppAccent accent = AppAccent.gold,
}) {
  final isLight = appTheme == AppTheme.light;
  final background = isLight
      ? const Color(0xFFF5F4F0)
      : const Color(0xFF101010);
  final surface = isLight ? Colors.white : const Color(0xFF1A1A1A);

  return ThemeData(
    useMaterial3: true,
    brightness: isLight ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent.color,
      brightness: isLight ? Brightness.light : Brightness.dark,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: isLight
          ? const Color(0xFF111111)
          : const Color(0xFFFFD76A),
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(style: interactiveButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: interactiveButtonStyle),
    textButtonTheme: TextButtonThemeData(style: interactiveButtonStyle),
    iconButtonTheme: IconButtonThemeData(style: interactiveButtonStyle),
    cardTheme: CardThemeData(
      color: isLight ? Colors.white : surface,
      elevation: isLight ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isLight ? const Color(0xFFE3DFD5) : const Color(0xFF353020),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? const Color(0xFFF2F1ED) : const Color(0xFF202020),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
    required this.selectedAccent,
    required this.onAccentChanged,
    required super.child,
  });

  final AppTheme selectedTheme;
  final ValueChanged<AppTheme> onThemeChanged;
  final AppAccent selectedAccent;
  final ValueChanged<AppAccent> onAccentChanged;

  static AppThemeScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()!;

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) =>
      selectedTheme != oldWidget.selectedTheme ||
      selectedAccent != oldWidget.selectedAccent;
}

const ButtonStyle interactiveButtonStyle = ButtonStyle(
  animationDuration: Duration(milliseconds: 180),
);

Color accentColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary;

class EskilerdenBrand extends StatefulWidget {
  const EskilerdenBrand({super.key, this.fontSize = 32});

  final double fontSize;

  @override
  State<EskilerdenBrand> createState() => _EskilerdenBrandState();
}

class _EskilerdenBrandState extends State<EskilerdenBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final movement = _controller.value * 2 - 1;
            final accent = accentColor(context);
            return LinearGradient(
              begin: Alignment(movement - 1, 0),
              end: Alignment(movement + 1, 0),
              colors: [
                accent,
                accent,
                Color.lerp(
                  accent,
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                  0.4,
                )!,
                accent,
                accent,
              ],
              stops: const [0, 0.44, 0.5, 0.56, 1],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        'eskilerden',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -widget.fontSize * 0.055,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}
