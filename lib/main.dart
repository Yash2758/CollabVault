import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/auth_data_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the auth controller
  authController = await AuthDataController.create();
  
  runApp(const MyApp());
}

late final AuthDataController authController;
final ValueNotifier<bool> userLoggedInNotifier = ValueNotifier<bool>(false);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: authController.userLoggedInNotifier,
      builder: (context, loggedIn, _) {
        return MaterialApp(
          title: 'CollabVault',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          home: loggedIn
              ? HomeScreen(authController: authController)
              : LoginScreen(
                  authController: authController,
                  userLoggedInNotifier: authController.userLoggedInNotifier,
                ),
          routes: {
            '/home': (context) => HomeScreen(authController: authController),
            '/login': (context) => LoginScreen(
                  authController: authController,
                  userLoggedInNotifier: authController.userLoggedInNotifier,
                ),
          },
        );
      },
    );
  }
}
