import 'package:flutter/material.dart';
import '../../services/db_service.dart';
import 'chat_screen.dart';

class SelectUserScreen extends StatefulWidget {
  final int currentUserId;
  final int userGroupId;

  const SelectUserScreen({
    super.key,
    required this.currentUserId,
    required this.userGroupId,
  });

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupUsers();
  }

  Future<void> _loadGroupUsers() async {
    try {
      final users = await DBService.getGroupUsers(
        widget.userGroupId,
        widget.currentUserId,
      );
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Ошибка загрузки пользователей: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startChat(Map<String, dynamic> selectedUser) async {
    try {
      print('🔍 Попытка создать чат:');
      print('  Текущий пользователь: ${widget.currentUserId}');
      print('  Выбранный пользователь: ${selectedUser['id']} (${selectedUser['first_name']})');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final chatData = await DBService.createPrivateChat(
        widget.currentUserId,
        selectedUser['id'] as int,
      );
      
      print('📦 Ответ от сервера: $chatData');

      if (mounted) Navigator.pop(context); // Убираем лоадер

      if (chatData != null) {
        final chatId = chatData['chat_id'] as int;
        final chatName = '${selectedUser['first_name']} ${selectedUser['last_name']}'.trim();
        
        // 🔥 ВОЗВРАЩАЕМ РЕЗУЛЬТАТ вместо pushReplacement
        if (mounted) {
          Navigator.pop(context, {
            'chatId': chatId,
            'chatName': chatName.isEmpty ? 'Личный чат' : chatName,
            'unreadCount': 0,
          });
        }
      } else {
        print('❌ chatData is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось создать чат'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('💥 Ошибка в _startChat: $e');
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFF),
      appBar: AppBar(
        title: const Text('Новый чат'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : _users.isEmpty
              ? const Center(
                  child: Text(
                    'В вашей группе нет других участников',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final firstName = user['first_name'] ?? '';
                    final lastName = user['last_name'] ?? '';
                    final avatarUrl = user['avatar_url'] as String?;
                    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                    
                    return InkWell(
                      onTap: () => _startChat(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE0E0E0),
                              ),
                              child: ClipOval(
                                child: hasAvatar
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 24, color: Color(0xFF9E9E9E)),
                                      )
                                    : const Icon(Icons.person, size: 24, color: Color(0xFF9E9E9E)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$firstName $lastName'.trim(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    user['login'] ?? '',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}