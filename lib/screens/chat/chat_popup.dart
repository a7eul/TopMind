import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/db_service.dart';

class ChatPopup extends StatefulWidget {
  final int chatId;
  final String chatName;
  final String? currentAvatar;
  final int currentUserId;
  final String chatType;

  const ChatPopup({
    super.key,
    required this.chatId,
    required this.chatName,
    this.currentAvatar,
    required this.currentUserId,
    this.chatType = 'group',
  });

  @override
  State<ChatPopup> createState() => _ChatPopupState();
}

class _ChatPopupState extends State<ChatPopup> {
  Map<String, dynamic>? _chatInfo;
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _otherUser;
  List<Map<String, dynamic>> _sharedChats = [];
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    try {
      final info = await DBService.getChatInfo(widget.chatId);
      final members = await DBService.getChatMembers(widget.chatId);

      if (widget.chatType == 'private') {
        final others = members.where((m) => m['id'] != widget.currentUserId).toList();
        _otherUser = others.isNotEmpty ? others.first : null;

        if (_otherUser != null) {
          _sharedChats = await DBService.getSharedGroupChats(
            widget.currentUserId,
            _otherUser!['id'] as int,
          );
        }
      }

      if (mounted) {
        setState(() {
          _chatInfo = info;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeChatAvatar() async {
    if (widget.chatType == 'private') return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || !mounted) return;

    try {
      setState(() => _isLoading = true);

      final newUrl = await DBService.updateChatAvatar(
        widget.chatId,
        pickedFile.path,
      );

      if (newUrl != null && mounted) {
        setState(() {
          if (_chatInfo != null) _chatInfo!['image_url'] = newUrl;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар чата обновлен'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleNotifications() async {
    final success = await DBService.toggleChatNotifications(
      widget.chatId,
      widget.currentUserId,
      !_notificationsEnabled,
    );

    if (success && mounted) {
      setState(() => _notificationsEnabled = !_notificationsEnabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_notificationsEnabled ? 'Уведомления включены' : 'Уведомления выключены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showFullAvatar(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = widget.chatType == 'private';

    String displayName;
    String? displayAvatar;
    int? displayUserId;

    if (isPrivate) {
      displayName = '${_otherUser?['first_name'] ?? ''} ${_otherUser?['last_name'] ?? ''}'.trim();
      displayAvatar = _otherUser?['avatar_url'] as String?;
      displayUserId = _otherUser?['id'] as int?;
    } else {
      displayName = _chatInfo?['name']?.toString() ?? widget.chatName;
      displayAvatar = _chatInfo?['image_url']?.toString() ?? widget.currentAvatar;
      displayUserId = null;
    }

    final hasAvatar = displayAvatar != null && displayAvatar.isNotEmpty;

    if (displayName.isEmpty) {
      displayName = isPrivate ? 'Пользователь' : 'Чат';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: hasAvatar ? () => _showFullAvatar(displayAvatar!) : null,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE0E0E0),
                                border: Border.all(color: Colors.grey[300]!, width: 3),
                              ),
                              child: ClipOval(
                                child: hasAvatar
                                    ? Image.network(
                                        displayAvatar!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          isPrivate ? Icons.person : Icons.group,
                                          size: 50,
                                          color: const Color(0xFF9E9E9E),
                                        ),
                                      )
                                    : Icon(
                                        isPrivate ? Icons.person : Icons.group,
                                        size: 50,
                                        color: const Color(0xFF9E9E9E),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasAvatar)
                            const Text(
                              'Нажмите для увеличения',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isPrivate && displayUserId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ID: $displayUserId',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (!isPrivate) ...[
                            _buildOptionButton(
                              icon: Icons.camera_alt_outlined,
                              text: 'Изменить аватар',
                              onTap: _changeChatAvatar,
                            ),
                            const SizedBox(height: 8),
                          ],
                          _buildOptionButton(
                            icon: _notificationsEnabled
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_off_outlined,
                            text: _notificationsEnabled
                                ? 'Выключить уведомления'
                                : 'Включить уведомления',
                            onTap: _toggleNotifications,
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: Colors.grey[200]),
                    if (isPrivate && _sharedChats.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Общие чаты',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ..._sharedChats.map((chat) => _buildSharedChat(chat)),
                          ],
                        ),
                      ),
                      Container(height: 1, color: Colors.grey[200]),
                    ],
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Участники',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ..._members.map((member) => _buildParticipant(
                                firstName: member['first_name'] ?? '',
                                lastName: member['last_name'] ?? '',
                                avatarUrl: member['avatar_url'],
                              )).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

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
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipant({
    required String firstName,
    required String lastName,
    String? avatarUrl,
  }) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final fullName = '$firstName $lastName'.trim();
    final isEmpty = fullName.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE0E0E0),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 20, color: Color(0xFF9E9E9E)),
                    )
                  : const Icon(Icons.person, size: 20, color: Color(0xFF9E9E9E)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEmpty ? 'Пользователь' : fullName,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedChat(Map<String, dynamic> chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              chat['name']?.toString() ?? 'Групповой чат',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}