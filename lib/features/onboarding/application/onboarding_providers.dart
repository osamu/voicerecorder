import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// オンボーディング完了を永続化する（settings.onboardingComplete='true'）。
final markOnboardingCompleteProvider = Provider<Future<void> Function()>((ref) {
  return () => ref
      .read(settingsDaoProvider)
      .setValue(kOnboardingCompleteKey, 'true');
});
