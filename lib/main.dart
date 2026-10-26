import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ayarlar.dart';
import 'uygulama.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } catch (error) {
      debugPrint('Önceki oturum kapatılırken sunucuya ulaşılamadı: $error');
    }
  }
  runApp(const AntiqueAdminApp());
}
