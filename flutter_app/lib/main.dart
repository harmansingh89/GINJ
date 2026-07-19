import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ginj/services/app_state.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/gurbani_list_screen.dart';
import 'screens/prize_selection_screen.dart';
import 'screens/delivery_address_screen.dart';
import 'screens/submission_status_screen.dart';
import 'screens/submission_history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/edit_user_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  await AppState.initialize();
  runApp(const GinjApp());
}

class GinjApp extends StatelessWidget {
  const GinjApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = AppState.api.token != null
        ? (AppState.userId != null
            ? (AppState.userProfileId != null ? '/home' : '/user-profile')
            : '/login')
        : '/signup';

    return MaterialApp(
      title: 'GINJ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.notoSansGurmukhiTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/user-profile': (context) => const UserProfileScreen(),
        '/home': (context) => const HomeScreen(),
        '/edit-user-profile': (context) => const EditUserProfileScreen(),
        '/gurbani-list': (context) => const GurbaniListScreen(),
        '/prize-list': (context) => const PrizeSelectionScreen(),
        '/delivery-address': (context) => const DeliveryAddressScreen(),
        '/status': (context) => const SubmissionStatusScreen(),
        '/history': (context) => const SubmissionHistoryScreen(),
      },
    );
  }
}
