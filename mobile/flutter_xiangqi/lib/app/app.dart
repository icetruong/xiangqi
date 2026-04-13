import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/audio/audio_service.dart';
import 'router.dart';
import 'theme.dart';

class XiangqiApp extends ConsumerWidget {
  const XiangqiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    // Eagerly initialize AudioService so BGM starts looping if unmuted
    ref.watch(audioServiceProvider);

    return MaterialApp.router(
      title: 'Xiangqi',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
