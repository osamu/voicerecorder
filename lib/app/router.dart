import 'package:flutter/material.dart';

import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/recordings_list/presentation/playback_screen.dart';
import '../features/recordings_list/presentation/recordings_list_screen.dart';
import '../features/recordings_list/presentation/transcript_view_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// ルート名の定数とルーティング解決（DESIGN §10 の画面構成）。
abstract final class Routes {
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String playback = '/playback';
  static const String transcript = '/transcript';
}

/// onGenerateRoute によるルーティング。引数付き画面は settings.arguments で受ける。
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return _page(settings, const RecordingsListScreen());
      case Routes.onboarding:
        return _page(settings, const OnboardingScreen());
      case Routes.settings:
        return _page(settings, const SettingsScreen());
      case Routes.playback:
        final id = settings.arguments as String;
        return _page(settings, PlaybackScreen(recordingId: id));
      case Routes.transcript:
        final id = settings.arguments as String;
        return _page(settings, TranscriptViewScreen(recordingId: id));
      default:
        return _page(
          settings,
          const Scaffold(body: Center(child: Text('画面が見つかりません'))),
        );
    }
  }

  static MaterialPageRoute<dynamic> _page(RouteSettings settings, Widget child) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }

  // ---- 型安全なナビゲーションヘルパ ----

  static Future<void> toSettings(BuildContext context) =>
      Navigator.of(context).pushNamed(Routes.settings);

  static Future<void> toPlayback(BuildContext context, String recordingId) =>
      Navigator.of(context).pushNamed(Routes.playback, arguments: recordingId);

  static Future<void> toTranscript(BuildContext context, String recordingId) =>
      Navigator.of(context).pushNamed(Routes.transcript, arguments: recordingId);
}
