import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DBService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>?> login(String login, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        // Сохраняем пользователя локально
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(user));
        return user;
      }
      return null;
    } catch (e) {
      print('Ошибка входа: $e');
      return null;
    }
  }

  // получение юзера
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) return null;
    return jsonDecode(userJson);
  }

  // обновление данных с серва
  static Future<Map<String, dynamic>?> fetchUser(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(user));
        return user;
      }
      return null;
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
      return null;
    }
  }

  // обновление профиля
static Future<bool> updateProfile(int userId, String firstName, String lastName) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'first_name': firstName, 'last_name': lastName}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

  // расписание
  static Future<List<Map<String, dynamic>>> getSchedule(
    int groupId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/schedule').replace(queryParameters: {
        'group_id': groupId.toString(),
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Ошибка расписания: $e');
      return [];
    }
  }

  // чаты
  static Future<List<Map<String, dynamic>>> getUserChats(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chats/$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка чатов: $e');
      return [];
    }
  }

  // соо чата
  static Future<List<Map<String, dynamic>>> getMessages(int chatId, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages').replace(queryParameters: {
          'limit': limit.toString(),
        }),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Разворачиваем список, так как сервер отдает от новых к старым
        return data.cast<Map<String, dynamic>>().reversed.toList();
      }
      return [];
    } catch (e) {
      print('Ошибка сообщений: $e');
      return [];
    }
  }

  // отправка соо
  static Future<bool> sendMessage(int chatId, int senderId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'sender_id': senderId.toString(),
          'content': content,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка отправки: $e');
      return false;
    }
  }

  static Future<bool> register(String firstName, String lastName, String login, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'login': login,
          'password': password,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Ошибка регистрации: $e');
      return false;
    }
  }
}

