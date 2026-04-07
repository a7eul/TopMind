import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/chats_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
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
        // Экран входа
        '/': (context) => const LoginScreen(),
        
        // Экран регистрации
        '/register': (context) => const RegisterScreen(),
        
        // Главная (список чатов)
        '/main': (context) => const ChatsListScreen(),
        
        // Расписание
        '/schedule': (context) => const ScheduleScreen(),
        
        // Профиль
        '/profile': (context) => const ProfileScreen(),
      },
      // Экран чата с параметрами
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: args['chatName'] ?? 'Чат',
              chatId: args['chatId'] ?? '0',
            ),
          );
        }
        return null;
      },
    );
  }
}