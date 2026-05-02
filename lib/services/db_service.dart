import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class DBService {
  static const baseUrl = 'https://college-api-5wro.onrender.com';

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
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson == null) return null;
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateProfile(int userId, String firstName, String lastName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'first_name': firstName, 'last_name': lastName}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> uploadAvatar(int userId, Uint8List fileBytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/users/$userId/avatar');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['avatar_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
      return [];
    }
  }

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
      return [];
    }
  }

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
          return data.map((item) => item as Map<String, dynamic>).toList().reversed.toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

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
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getChatInfo(int chatId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chats/$chatId/info'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
      return [];
    }
  }

  static Future<String?> updateChatAvatar(int chatId, Uint8List fileBytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/chats/$chatId/avatar');
      final request = http.MultipartRequest('PUT', uri);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['avatar_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
      return false;
    }
  }

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
      return 0;
    }
  }

  static Future<bool> markAsRead(int chatId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatId/mark-read'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'user_id': userId.toString()},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

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
      return [];
    }
  }

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
      return null;
    }
  }

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
      return [];
    }
  }

  static Future<bool> sendImageMessage(int chatId, int senderId, Uint8List imageBytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/chats/$chatId/messages/image');
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['sender_id'] = senderId.toString()
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: filename,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        
      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendFileMessage(
    int chatId,
    int senderId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      if (fileBytes.isEmpty || fileName.isEmpty) {
        return false;
      }

      final uri = Uri.parse('$baseUrl/chats/$chatId/messages/file');
      
      final safeFileName = fileName
          .replaceAll(RegExp(r'[^\x20-\x7E]'), '_')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['sender_id'] = senderId.toString()
        ..fields['file_name'] = fileName
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: safeFileName.isEmpty ? 'uploaded_file' : safeFileName,
            contentType: MediaType('application', 'octet-stream'),
          ),
        );
      
      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}