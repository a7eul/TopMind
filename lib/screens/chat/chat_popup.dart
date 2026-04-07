import 'package:flutter/material.dart';

class ChatPopup extends StatelessWidget {
  final String chatId;

  const ChatPopup({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок чата
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Название чата
                  const Text(
                    'Студенты РПО',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Кнопка "Изменить аватар"
                  _buildOptionButton(
                    icon: Icons.camera_alt_outlined,
                    text: 'Изменить аватар',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Логика изменения аватара
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Кнопка "Выключить уведомления"
                  _buildOptionButton(
                    icon: Icons.notifications_off_outlined,
                    text: 'Выключить уведомления',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Логика уведомлений
                    },
                  ),
                ],
              ),
            ),
            
            // Разделитель
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            
            // Список участников
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Участники:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Участник 1
                  _buildParticipant(
                    name: 'Макарова Елизавета',
                    avatarColor: Colors.pink[100]!,
                  ),
                  const SizedBox(height: 12),
                  
                  // Участник 2
                  _buildParticipant(
                    name: 'Кондакова Ксения',
                    avatarColor: Colors.blue[100]!,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Виджет кнопки опции
  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет участника
  Widget _buildParticipant({
    required String name,
    required Color avatarColor,
  }) {
    return Row(
      children: [
        // Аватарка (заглушка)
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          // Здесь потом можно добавить фото
          // child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        
        // Имя
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}