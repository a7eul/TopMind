import 'package:flutter/material.dart';
import '../chat/chat_screen.dart'; // Импорт для перехода в чат

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {  
  // Индекс активного пункта меню (1 = Чаты)
  int _activeIndex = 1;

  // Мок-данные для списка чатов
  final List<Map<String, String>> _chats = [
    {'name': 'Студенты РПО', 'lastMsg': 'Расписание на завтра...', 'time': '10:00'},
    {'name': 'Одногруппники', 'lastMsg': 'Кто сделал домашку?', 'time': '09:45'},
    {'name': 'Преподаватель', 'lastMsg': 'Занятие переносится', 'time': 'Вчера'},
    {'name': 'Объявления', 'lastMsg': 'Собрание в 14:00', 'time': 'Вчера'},
    {'name': 'Спортклуб', 'lastMsg': 'Тренировка в пятницу', 'time': 'Пн'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFF), // Светлый фон
      // Красная полоса сверху
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text(
                'Чаты',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            
            Expanded(
              child: Stack(
                children: [
                  // Список чатов
                  _buildChatList(),
                  
                  // Плавающее меню навигации справа
                  Positioned(
                    right: 10,
                    top: 100,
                    bottom: 100,
                    child: _buildFloatingNav(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет списка чатов
  Widget _buildChatList() {
    return Padding(
      padding: const EdgeInsets.only(right: 60.0), // Отступ чтобы не перекрывать меню
      child: Container(
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
          itemBuilder: (context, index) {
            final chat = _chats[index];
            return _buildChatItem(chat);
          },
        ),
      ),
    );
  }

  // Виджет одного элемента чата
  Widget _buildChatItem(Map<String, String> chat) {
    return InkWell(
      onTap: () {
        // Переход на экран чата
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: chat['name']!,
              chatId: '1',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Аватарка (белый кружок с тенью)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMsg']!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Время (опционально)
            Text(
              chat['time']!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Плавающее меню навигации
  Widget _buildFloatingNav() {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavItem(Icons.person_outline, 'Профиль', 0),
          const SizedBox(height: 20),
          _buildNavItem(Icons.chat, 'Чаты', 1, isActive: true),
          const SizedBox(height: 20),
          _buildNavItem(Icons.calendar_today, 'Расписание', 2),
          const SizedBox(height: 20),
          _buildNavItem(Icons.settings, 'Настройки\n(будут потом)', 3),
        ],
      ),
    );
  }

  // Элемент меню
  Widget _buildNavItem(IconData icon, String label, int index, {bool isActive = false}) {
    final bool isSelected = _activeIndex == index || isActive;
    final Color color = isSelected ? const Color(0xFFE53935) : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          // Переход на профиль (заглушка)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль скоро!')));
        } else if (index == 2) {
          // Переход на расписание (заглушка)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Расписание скоро!')));
        } else if (index == 3) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки пока нет!')));
        } else {
          setState(() => _activeIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}