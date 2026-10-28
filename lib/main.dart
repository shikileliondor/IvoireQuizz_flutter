import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/app_audio_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final scale = preferences.getDouble('accessibility_text_scale') ?? 1.0;
  final highContrast =
      preferences.getBool('accessibility_high_contrast') ?? false;
  final reduceMotion =
      preferences.getBool('accessibility_reduce_motion') ?? false;
  appTextScale.value = scale;
  appHighContrast.value = highContrast;
  appReduceMotion.value = reduceMotion;
  await AppAudioController.instance.initialize();
  runApp(const ProviderScope(child: IvoireQuizApp()));
}

final ValueNotifier<double> appTextScale = ValueNotifier<double>(1.0);
final ValueNotifier<bool> appHighContrast = ValueNotifier<bool>(false);
final ValueNotifier<bool> appReduceMotion = ValueNotifier<bool>(false);

class IvoireQuizApp extends ConsumerWidget {
  const IvoireQuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<double>(
      valueListenable: appTextScale,
      builder: (context, scale, _) => ValueListenableBuilder<bool>(
        valueListenable: appHighContrast,
        builder: (context, highContrast, _) => ValueListenableBuilder<bool>(
          valueListenable: appReduceMotion,
          builder: (context, reduceMotion, _) => MaterialApp.router(
            title: 'IvoireQuiz',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light.copyWith(
              colorScheme: AppTheme.light.colorScheme.copyWith(
                primary: highContrast ? const Color(0xFF9C3F00) : null,
                onSurface: highContrast ? const Color(0xFF000000) : null,
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: reduceMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
  }
}
