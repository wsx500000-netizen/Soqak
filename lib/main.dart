import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/services/marketplace_state.dart';
import 'package:shop/services/supabase_service.dart';
import 'package:shop/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(MarketplaceScope(
    notifier: MarketplaceState(),
    child: const MyApp(),
  ));
}

// Thanks for using our template. You are using the free version of the template.
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      title: 'سوقك',
      builder: (context, child) {
        final state = MarketplaceScope.of(context);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child!,
              if (state.loadError != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: const Color(0xFFFFF3CD),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(state.loadError!)),
                            TextButton(
                              onPressed: state.retryLoading,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      theme: AppTheme.lightTheme(context),
      // Dark theme is inclided in the Full template
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      initialRoute: onbordingScreenRoute,
    );
  }
}
