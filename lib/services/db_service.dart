import 'package:postgres/postgres.dart';

class DBService {
  static PostgreSQLConnection? _conn;

  static const String host = 'localhost';
  static const int port = 5432;
  static const String database = 'topmind_messenger';
  static const String username = 'postgres';
  static const String password = 'L2525iza2008';

  static Future<PostgreSQLConnection> connection() async {
    if (_conn != null && !_conn!.isClosed) {
      return _conn!;
    }

    _conn = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
      useSSL: false,
      timeoutInSeconds: 30,
    );

    await _conn!.open();
    return _conn!;
  }

  static Future<Map<String, dynamic>?> login(String login, String pass) async {
    final conn = await connection();
    final result = await conn.query(
      'SELECT id, first_name, last_name FROM public.users WHERE login = @login AND password_hash = @pass',
      substitutionValues: {'login': login, 'pass': pass},
    );
    return result.isNotEmpty ? result.first.toColumnMap() : null;
  }

static Future<bool> register(
  String firstName, String lastName, String login, String password
) async {
  final conn = await connection();
  
  print('🔍 DEBUG: Ищем логин "$login"');
  
  final allLogins = await conn.query('SELECT login FROM public.users ORDER BY login');
  print('Все логины в БД: ${allLogins.map((r) => r.toColumnMap()).toList()}');
  
  final existing = await conn.query(
    'SELECT id, login FROM public.users WHERE login = @login',
    substitutionValues: {'login': login},
  );
  
  print('Найдено для "$login": ${existing.length} записей');
  
  if (existing.isNotEmpty) {
    print('Логин существует: ${existing.first.toColumnMap()}');
    return false;
  }

  // INSERT
  await conn.execute(
    'INSERT INTO public.users (first_name, last_name, login, password_hash) VALUES (@firstName, @lastName, @login, @password)',
    substitutionValues: {
      'firstName': firstName,
      'lastName': lastName,
      'login': login,
      'password': password,
    },
  );
  
  print('"$login" добавлен!');
  return true;
}

  static Future<List<Map<String, dynamic>>> getUserChats(int userId) async {
    final conn = await connection();
    final result = await conn.query(
      'SELECT DISTINCT c.id, c.name FROM public.chats c JOIN public.chat_members cm ON c.id = cm.chat_id WHERE cm.user_id = @userId',
      substitutionValues: {'userId': userId},
    );
    return result.map((row) => row.toColumnMap()).toList();
  }

  static Future<List<Map<String, dynamic>>> getChatMessages(int chatId, {int limit = 50}) async {
    final conn = await connection();
    final result = await conn.query(
      'SELECT m.id, m.content, m.created_at, u.first_name AS sender FROM public.messages m JOIN public.users u ON m.sender_id = u.id WHERE m.chat_id = @chatId ORDER BY m.created_at DESC LIMIT @limit',
      substitutionValues: {'chatId': chatId, 'limit': limit},
    );
    return result.map((row) => row.toColumnMap()).toList();
  }

  static Future<bool> sendMessage(int chatId, int userId, String content) async {
    try {
      final conn = await connection();
      await conn.execute(
        'INSERT INTO public.messages (chat_id, sender_id, content) VALUES (@chatId, @userId, @content)',
        substitutionValues: {'chatId': chatId, 'userId': userId, 'content': content},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}