import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class DBService {
  // 🌐 АДРЕС СЕРВЕРА:
  // • Android Emulator: 'http://10.0.2.2:8000'
  // • iOS Simulator / Web / Desktop: 'http://127.0.0.1:8000'
  // • Реальный телефон: 'http://192.168.X.X:8000' (IP компьютера в Wi-Fi)
  static const baseUrl = 'http://127.0.0.1:8000';

  // 🔐 АВТОРИЗАЦИЯ
  static Future<Map<String, dynamic>?> login(String login, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(user));
        return user;
      }
      print('⚠️ Ошибка входа: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Ошибка сети при входе: $e');
      return null;
    }
  }

  // 👤 Текущий пользователь (из локального хранилища)
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson == null) return null;
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Ошибка чтения пользователя: $e');
      return null;
    }
  }

  // 🔄 Обновить данные пользователя с сервера
  static Future<Map<String, dynamic>?> fetchUser(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(user));
        return user;
      }
      return null;
    } catch (e) {
      print('❌ Ошибка загрузки пользователя: $e');
      return null;
    }
  }

  // ✏️ Обновление профиля
  static Future<bool> updateProfile(int userId, String firstName, String lastName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'first_name': firstName, 'last_name': lastName}),
      );
      if (response.statusCode != 200) {
        print('⚠️ Ошибка обновления: ${response.statusCode} - ${response.body}');
      }
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка сети при обновлении: $e');
      return false;
    }
  }

  // 📸 Загрузка аватара
  static Future<String?> uploadAvatar(int userId, String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/users/$userId/avatar');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: path.basename(filePath),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['avatar_url'] as String?;
      }
      print('⚠️ Ошибка загрузки аватара: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Ошибка сети при загрузке аватара: $e');
      return null;
    }
  }

  // 📅 Расписание
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
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки расписания: $e');
      return [];
    }
  }

  // 💬 Список чатов пользователя
  static Future<List<Map<String, dynamic>>> getUserChats(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chats/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки чатов: $e');
      return [];
    }
  }

  // 💬 Сообщения чата
  static Future<List<Map<String, dynamic>>> getMessages(int chatId, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages').replace(queryParameters: {
          'limit': limit.toString(),
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Разворачиваем, так как сервер отдаёт от новых к старым
          return data.map((item) => item as Map<String, dynamic>).toList().reversed.toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки сообщений: $e');
      return [];
    }
  }

  // 📤 Отправка сообщения
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
      if (response.statusCode != 200) {
        print('⚠️ Ошибка отправки: ${response.statusCode} - ${response.body}');
      }
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка сети при отправке: $e');
      return false;
    }
  }

  // 🔐 Регистрация
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
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('⚠️ Ошибка регистрации: ${response.statusCode} - ${response.body}');
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Ошибка сети при регистрации: $e');
      return false;
    }
  }

    // 💬 Информация о чате
  static Future<Map<String, dynamic>?> getChatInfo(int chatId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chats/$chatId/info'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Ошибка загрузки инфо чата: $e');
      return null;
    }
  }

  // 👥 Участники чата
  static Future<List<Map<String, dynamic>>> getChatMembers(int chatId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chats/$chatId/members'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки участников: $e');
      return [];
    }
  }

  // 📸 Смена аватара чата
  static Future<String?> updateChatAvatar(int chatId, String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/chats/$chatId/avatar');
      final request = http.MultipartRequest('PUT', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: path.basename(filePath),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['avatar_url'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Ошибка смены аватара чата: $e');
      return null;
    }
  }

  // 🔔 Переключить уведомления
  static Future<bool> toggleChatNotifications(int chatId, int userId, bool enabled) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/chats/$chatId/notifications').replace(queryParameters: {
          'user_id': userId.toString(),
          'enabled': enabled.toString(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка настройки уведомлений: $e');
      return false;
    }
  }

  // 🔔 Получить количество непрочитанных
static Future<int> getUnreadCount(int chatId, int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/chats/$chatId/unread').replace(queryParameters: {
        'user_id': userId.toString(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['unread_count'] as int? ?? 0;
    }
    return 0;
  } catch (e) {
    print('❌ Ошибка получения непрочитанных: $e');
    return 0;
  }
}

// 🟢 Отметить чат как прочитанный
static Future<bool> markAsRead(int chatId, int userId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/$chatId/mark-read'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'user_id': userId.toString()},
    );
    return response.statusCode == 200;
  } catch (e) {
    print('❌ Ошибка отметки прочитанного: $e');
    return false;
  }
}

// 👥 Получить пользователей группы
static Future<List<Map<String, dynamic>>> getGroupUsers(int groupId, int currentUserId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/users').replace(queryParameters: {
        'current_user_id': currentUserId.toString(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
    }
    return [];
  } catch (e) {
    print('❌ Ошибка загрузки пользователей группы: $e');
    return [];
  }
}

// 💬 Создать личный чат
static Future<Map<String, dynamic>?> createPrivateChat(int user1Id, int user2Id) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/private').replace(queryParameters: {
        'user1_id': user1Id.toString(),
        'user2_id': user2Id.toString(),
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  } catch (e) {
    print('❌ Ошибка создания чата: $e');
    return null;
  }
}

// 🔥 Общие групповые чаты между двумя пользователями
static Future<List<Map<String, dynamic>>> getSharedGroupChats(int userId1, int userId2) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/shared-chats').replace(queryParameters: {
        'user1_id': userId1.toString(),
        'user2_id': userId2.toString(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
    }
    return [];
  } catch (e) {
    print('❌ Ошибка общих чатов: $e');
    return [];
  }
}

// 📸 Отправка фото
// 📸 Отправка фото
static Future<bool> sendImageMessage(int chatId, int senderId, String imagePath) async {
  try {
    print('📤 Отправка фото: $imagePath');
    
    final uri = Uri.parse('$baseUrl/chats/$chatId/messages/image');
    final request = http.MultipartRequest('POST', uri)
      ..fields['sender_id'] = senderId.toString()
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      ));
    
    print('📮 Отправляю запрос...');
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    print('📦 Ответ сервера: ${response.statusCode}');
    print('📄 Тело ответа: $responseBody');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Фото отправлено успешно');
      return true;
    } else {
      print('❌ Ошибка: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ Ошибка отправки фото: $e');
    return false;
  }
}

// 📎 Отправка файла
static Future<bool> sendFileMessage(
  int chatId,
  int senderId,
  String filePath,
  String fileName,
) async {
  try {
    print('📤 Отправка файла: $fileName ($filePath)');
    
    final uri = Uri.parse('$baseUrl/chats/$chatId/messages/file');
    final request = http.MultipartRequest('POST', uri)
      ..fields['sender_id'] = senderId.toString()
      ..fields['file_name'] = fileName
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
      ));
    
    print('📮 Отправляю запрос...');
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    print('📦 Ответ сервера: ${response.statusCode}');
    print('📄 Тело ответа: $responseBody');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Файл отправлен успешно');
      return true;
    } else {
      print('❌ Ошибка: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ Ошибка отправки файла: $e');
    return false;
  }
}
}