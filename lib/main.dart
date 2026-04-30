import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/chats_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/db_service.dart';

Future<void> testDB() async {
  try {
    final chats = await DBService.getUserChats(1);
    debugPrint('Чаты загружены: ${chats.length}');
  } catch (e) {
    debugPrint('DB error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await testDB();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOP Mind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFFF0FFFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/main': (context) => const ChatsListScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return null;
          }

          final chatId = args['chatId'] as int;
          final chatName = args['chatName'] as String;
          final userId = args['userId'] as int;

          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: chatName,
              chatId: chatId,
              userId: userId,
            ),
          );
        }
        return null;
      },
    );
  }
}