import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'features/meeting/presentation/bloc/meeting_bloc.dart';
import 'features/meeting/presentation/bloc/meeting_event.dart';
import 'features/meeting/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnv();
  final dependencies = await AppDependencies.create(
    geminiApiKey: _resolveGeminiApiKey(),
    geminiModel: _resolveGeminiModel(),
  );
  runApp(RowApp(dependencies: dependencies));
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Permite o app subir sem arquivo .env em dev/local.
  }
}

String _resolveGeminiApiKey() {
  final envKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  if (envKey.isNotEmpty) {
    return envKey;
  }

  // Fallback para manter compatibilidade com --dart-define.
  return const String.fromEnvironment('GEMINI_API_KEY').trim();
}

String _resolveGeminiModel() {
  final envModel = dotenv.env['GEMINI_MODEL']?.trim() ?? '';
  if (envModel.isNotEmpty) {
    return envModel;
  }

  final defineModel = const String.fromEnvironment('GEMINI_MODEL').trim();
  if (defineModel.isNotEmpty) {
    return defineModel;
  }

  // Evita bloqueio de quota observado em gemini-2.0-flash em alguns projetos.
  return 'gemini-2.5-flash';
}

class RowApp extends StatefulWidget {
  const RowApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<RowApp> createState() => _RowAppState();
}

class _RowAppState extends State<RowApp> {
  @override
  void dispose() {
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MeetingBloc>.value(
      value: widget.dependencies.meetingBloc..add(const MeetingsRequested()),
      child: MaterialApp(
        title: 'ROW',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
