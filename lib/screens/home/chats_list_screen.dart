import 'package:flutter/material.dart';
import '../../services/db_service.dart';  
import '../widgets/side_menu.dart';
import '../chat/chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final user = await DBService.getCurrentUser();  
      final userId = user?['id'] ?? 1;
      
      final chats = await DBService.getUserChats(userId);
      print('Загружено чатов: ${chats.length}');
      
      setState(() {
        _chats = chats.map((chat) => {
          'id': chat['id'].toString(),
          'name': chat['name'] ?? 'Без названия',
          'lastMsg': chat['last_message'] ?? 'Пока нет сообщений',
          'time': _formatTime(chat['last_message_time'] ?? DateTime.now()),
          'avatar': chat['image_url'] ?? '',
          'unread': chat['unread_count'] ?? 0,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка чатов: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) return '${time.day}.${time.month}';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
            // Левая часть
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
                              'Пока нет чатов\nНажмите "+" для создания',
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
        onPressed: _createNewChat,  // TODO
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _createNewChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание чата...')),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final unreadCount = chat['unread'] as int? ?? 0;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: chat['name'],
              chatId: chat['id'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            // Аватар чата
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: chat['avatar'].isNotEmpty
                  ? DecorationImage(image: NetworkImage(chat['avatar']), fit: BoxFit.cover)
                  : null,
                color: chat['avatar'].isEmpty ? Colors.grey[200] : null,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMsg'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Время
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}