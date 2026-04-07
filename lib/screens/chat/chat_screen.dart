import 'package:flutter/material.dart';
import 'chat_popup.dart'; // Импортируем попап, который сделаем позже

class ChatScreen extends StatefulWidget {
  final String chatName;
  final String chatId;

  const ChatScreen({super.key, required this.chatName, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // Мок-данные (как на скриншоте)
  final List<Map<String, dynamic>> _messages = [
    {'sender': 'Ксения', 'text': '', 'type': 'text', 'isMe': false},
    {'sender': 'Учебка', 'text': '', 'type': 'image_placeholder', 'isMe': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFF),
      // Красная полоса сверху
      body: SafeArea(
        child: Column(
          children: [
            // 1. Верхняя панель (Header)
            _buildHeader(),
            
            // 2. Список сообщений
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageItem(msg);
                },
              ),
            ),
            
            // 3. Поле ввода (Footer)
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  // Виджет заголовка чата
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        // Можно добавить легкую тень внизу, если нужно
        // boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))]
      ),
      child: Row(
        children: [
          // Кнопка назад
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          // Название чата
          Expanded(
            child: Text(
              widget.chatName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Кружок справа (инфо о чате)
          GestureDetector(
            onTap: () {
              // Открываем попап
              showDialog(
                context: context,
                builder: (context) => ChatPopup(chatId: widget.chatId),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Виджет одного сообщения (Имя + Текст/Картинка)
  Widget _buildMessageItem(Map<String, dynamic> msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Имя отправителя
          Text(
            msg['sender'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // Пузырь сообщения
          if (msg['type'] == 'text')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Светло-серый фон как на макете
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Текст сообщения...', // Заглушка
                style: TextStyle(color: Colors.transparent), // Скрываем текст, чтобы было как на макете (пустой)
              ),
              // Если нужно показать реальный текст, убери color: Colors.transparent выше
            )
          else if (msg['type'] == 'image_placeholder')
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
        ],
      ),
    );
  }

  // Виджет поля ввода
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        // border: Border(top: BorderSide(color: Colors.grey, width: 0.5))
      ),
      child: Row(
        children: [
          // Скрепка
          Icon(Icons.attach_file, color: Colors.grey[600]),
          const SizedBox(width: 12),
          
          // Поле ввода
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Сообщение...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Кнопка отправки
          Icon(Icons.send, color: Colors.grey[800]),
        ],
      ),
    );
  }
}