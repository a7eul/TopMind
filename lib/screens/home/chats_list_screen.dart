import 'package:flutter/material.dart';
import '../../services/db_service.dart';
import '../widgets/side_menu.dart';
import '../chat/chat_screen.dart';
import '../chat/select_user_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final user = await DBService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка авторизации')),
          );
        }
        return;
      }

      _userId = user['id'] as int;
      final chats = await DBService.getUserChats(_userId!);

      if (!mounted) return;

      final updatedChats = <Map<String, dynamic>>[];
      for (final chat in chats) {
        final unread = await DBService.getUnreadCount(
          chat['id'] as int,
          _userId!,
        );

        String name = chat['name']?.toString().trim() ?? '';
        if (name.isEmpty) {
          name = chat['type'] == 'group' ? 'Групповой чат' : 'Личная переписка';
        }

        updatedChats.add({
          'id': chat['id'] as int,
          'name': name,
          'type': chat['type'] ?? 'group',
          'avatar': chat['image_url'] ?? '',
          'unread': unread,
        });
      }

      if (mounted) {
        setState(() {
          _chats = updatedChats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 90.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Text(
                      'Чаты',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                        : _chats.isEmpty
                            ? const Center(
                                child: Text(
                                  'Пока нет чатов',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _chats.length,
                                  itemBuilder: (context, index) => _buildChatItem(_chats[index]),
                                ),
                              ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                child: const SideMenu(activeIndex: 1),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _createNewChat() async {
    if (_userId == null) return;

    final user = await DBService.getCurrentUser();
    if (user == null) return;

    final groupId = user['group_id'] as int?;
    if (groupId == null || groupId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ваша группа не определена'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectUserScreen(
          currentUserId: _userId!,
          userGroupId: groupId,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadChats();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: result['chatId'] as int,
            chatName: result['chatName'] as String,
            userId: _userId!,
            unreadCount: result['unreadCount'] as int? ?? 0,
          ),
        ),
      );
    }
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final avatarUrl = chat['avatar'] as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final unreadCount = chat['unread'] as int? ?? 0;
    final chatName = chat['name']?.toString() ?? 'Чат';

    return InkWell(
      onTap: () {
        if (_userId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: chatName,
              chatId: chat['id'] as int,
              userId: _userId!,
              unreadCount: unreadCount,
              chatType: chat['type'] as String? ?? 'group',
            ),
          ),
        ).then((_) => _loadChats());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0E0E0)),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarIcon(chat['type']))
                    : _buildAvatarIcon(chat['type']),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(chatName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: const BoxDecoration(color: Color(0xFFE53935), borderRadius: BorderRadius.all(Radius.circular(12))),
                          child: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(chat['type'] == 'group' ? 'Групповой чат' : 'Личная переписка', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarIcon(String? type) {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: Icon(type == 'group' ? Icons.group : Icons.person, size: 24, color: const Color(0xFF9E9E9E)),
    );
  }
}