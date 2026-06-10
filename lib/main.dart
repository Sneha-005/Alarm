import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/alarm_provider.dart';
import 'screens/add_edit_alarm_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    final prefs = await SharedPreferences.getInstance();
    final firebaseService = FirebaseService();
    final notificationService = NotificationService();
    await notificationService.init();

    runApp(
      MyApp(
        prefs: prefs,
        firebaseService: firebaseService,
        notificationService: notificationService,
      ),
    );
  } catch (error, stackTrace) {
    runApp(AppInitError(error: error, stackTrace: stackTrace));
  }
}

class AppInitError extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const AppInitError({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Initialization Error',
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization Error')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App failed to initialize.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(error.toString()),
                const SizedBox(height: 16),
                Text(stackTrace.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseService firebaseService;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.prefs,
    required this.firebaseService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(firebaseService: firebaseService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AlarmProvider>(
          create:
              (_) => AlarmProvider(
                firebaseService: firebaseService,
                notificationService: notificationService,
                sharedPreferences: prefs,
              ),
          update: (_, auth, alarmProvider) {
            alarmProvider!..setUser(auth.user);
            return alarmProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Alarm Clock',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/addEdit': (context) => const AddEditAlarmScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.user != null) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
