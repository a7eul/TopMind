import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DBService {
  static PostgreSQLConnection? _conn;

  static const String host = 'localhost';
  static const int port = 5432;
  static const String database = 'topmind_messenger';
  static const String username = 'postgres';
  static const String password = 'L2525iza2008';

  static Future<PostgreSQLConnection> connection() async {
    if (_conn != null && !_conn!.isClosed) return _conn!;
        
    _conn = PostgreSQLConnection(
      host, port, database,
      username: username,
      password: password,
      useSSL: false,
      timeoutInSeconds: 30,
    );
    await _conn!.open();
    return _conn!;
  }

  // АВТОРИЗАЦИЯ
  static Future<Map<String, dynamic>?> login(String login, String pass) async {
    final conn = await connection();
    final result = await conn.query(
      'SELECT id, first_name, last_name, avatar_url FROM public.users WHERE login = @login AND password_hash = @pass',
      substitutionValues: {'login': login, 'pass': pass},
    );
    return result.isNotEmpty ? result.first.toColumnMap() : null;
  }

  static Future<bool> register(String firstName, String lastName, String login, String password) async {
    final conn = await connection();
    
    // Проверка уникальности логина
    final existing = await conn.query(
      'SELECT id FROM public.users WHERE login = @login',
      substitutionValues: {'login': login},
    );
    
    if (existing.isNotEmpty) {
      print('Логин "$login" уже существует');
      return false;
    }

    await conn.execute(
      'INSERT INTO public.users (first_name, last_name, login, password_hash) VALUES (@firstName, @lastName, @login, @password)',
      substitutionValues: {
        'firstName': firstName,
        'lastName': lastName,
        'login': login,
        'password': password, 
      },
    );
    
    print('"$login" зарегистрирован');
    return true;
  }

  // ЧАТЫ пользователя (групповые + личные)
  static Future<List<Map<String, dynamic>>> getUserChats(int userId) async {
    final conn = await connection();
    final result = await conn.query('''
      SELECT DISTINCT 
        c.id, c.name, c.image_url, c.type,
        COUNT(cm2.user_id) as member_count
      FROM public.chats c 
      JOIN public.chat_members cm ON c.id = cm.chat_id 
      LEFT JOIN public.chat_members cm2 ON c.id = cm2.chat_id
      WHERE cm.user_id = @userId
      GROUP BY c.id, c.name, c.image_url, c.type
      ORDER BY c.name
    ''', substitutionValues: {'userId': userId});
    return result.map((row) => row.toColumnMap()).toList();
  }

  // СООБЩЕНИЯ чата
  static Future<List<Map<String, dynamic>>> getChatMessages(int chatId, {int limit = 50}) async {
    final conn = await connection();
    final result = await conn.query('''
      SELECT 
        m.id, m.content, m.image_url, m.file_url, m.created_at,
        u.first_name, u.last_name, u.avatar_url,
        (SELECT COUNT(*) FROM public.messages WHERE chat_id = @chatId AND id > m.id) as unread_count
      FROM public.messages m
      JOIN public.users u ON m.sender_id = u.id
      WHERE m.chat_id = @chatId
      ORDER BY m.created_at ASC
      LIMIT @limit
    ''', substitutionValues: {'chatId': chatId, 'limit': limit});
    return result.map((row) => row.toColumnMap()).toList();
  }

  // ОТПРАВИТЬ сообщение
  static Future<bool> sendMessage(int chatId, int userId, String content, {String? imageUrl, String? fileUrl}) async {
    try {
      final conn = await connection();
      await conn.execute('''
        INSERT INTO public.messages (chat_id, sender_id, content, image_url, file_url) 
        VALUES (@chatId, @userId, @content, @imageUrl, @fileUrl)
      ''', substitutionValues: {
        'chatId': chatId,
        'userId': userId,
        'content': content,
        'imageUrl': imageUrl ?? '',
        'fileUrl': fileUrl ?? '',
      });
      print('Сообщение отправлено в чат $chatId');
      return true;
    } catch (e) {
      print('Ошибка отправки: $e');
      return false;
    }
  }

  // РАСПИСАНИЕ группы
  static Future<List<Map<String, dynamic>>> getGroupSchedule(int groupId) async {
    final conn = await connection();
    final result = await conn.query('''
      SELECT s.id, s.day_of_week, s.start_time, s.end_time, s.subject, s.teacher, s.room, g.name as group_name
      FROM public.schedules s
      JOIN public.groups g ON s.group_id = g.id
      WHERE s.group_id = @groupId
      ORDER BY s.day_of_week, s.start_time
    ''', substitutionValues: {'groupId': groupId});
    return result.map((row) => row.toColumnMap()).toList();
  }

  // ГРУППЫ пользователя
  static Future<List<Map<String, dynamic>>> getUserGroups(int userId) async {
    final conn = await connection();
    final result = await conn.query('''
      SELECT DISTINCT g.id, g.name, g.year
      FROM public.groups g
      JOIN public.users u ON u.group_id = g.id
      WHERE u.id = @userId
    ''', substitutionValues: {'userId': userId});
    return result.map((row) => row.toColumnMap()).toList();
  }

  // Закрыть соединение
  static Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) return null;
    return Map<String, dynamic>.from(jsonDecode(userJson));
  }
  static Future<bool> updateProfile(int userId, String firstName, String lastName) async {
  try {
    final conn = await connection();
    await conn.execute(
      'UPDATE public.users SET first_name = @firstName, last_name = @lastName WHERE id = @userId',
      substitutionValues: {
        'userId': userId, 
        'firstName': firstName, 
        'lastName': lastName
      },
    );
    print('Профиль userId=$userId обновлен');
    return true;
  } catch (e) {
    print('Ошибка update: $e');
    return false;
  }
}


}