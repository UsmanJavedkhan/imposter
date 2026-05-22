import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_web_options.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  // Required before any async work in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Firebase. On Android/iOS this reads the native config files
  // (google-services.json / GoogleService-Info.plist) automatically. On web
  // there is no native file, so we pass the web options explicitly.
  if (kIsWeb) {
    await Firebase.initializeApp(options: kWebFirebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

  // ProviderScope is what makes Riverpod work; it must wrap the whole app.
  runApp(const ProviderScope(child: ImposterApp()));
}

class ImposterApp extends StatelessWidget {
  const ImposterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imposter',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Dark canvas behind everything so transparent scaffolds (used so the
      // gradient can show) never fall through to a white page.
      builder: (context, child) => ColoredBox(
        color: AppColors.bgTop,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomeScreen(),
    );
  }
}
