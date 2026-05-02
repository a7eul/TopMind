import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import '../../services/db_service.dart';
import 'chat_popup.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  final int userId;
  final int unreadCount;
  final String chatType;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.userId,
    this.unreadCount = 0,
    this.chatType = 'group',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _selectedFileSize;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);
      final msgs = await DBService.getMessages(widget.chatId);
      if (!mounted) return;
      setState(() {
        _messages = msgs.reversed.toList();
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      DBService.markAsRead(widget.chatId, widget.userId);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      try {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
          _selectedFileBytes = null;
          _selectedFileName = null;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка чтения изображения: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
          _selectedFileSize = file.size;
          _selectedImageBytes = null;
          _selectedImageName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора файла: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelSelection() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  Future<void> _sendFileMessage() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;
    setState(() => _isUploading = true);
    try {
      final success = await DBService.sendFileMessage(
        widget.chatId,
        widget.userId,
        _selectedFileBytes!,
        _selectedFileName!,
      );
      if (success && mounted) {
        setState(() {
          _selectedFileBytes = null;
          _selectedFileName = null;
          _selectedFileSize = null;
          _isUploading = false;
        });
        await _loadMessages();
        _scrollToBottom();
      } else if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить файл'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isSending) return;
    final content = _controller.text.trim();
    _controller.clear();
    final tempIndex = _messages.length;
    setState(() {
      _isSending = true;
      _messages.add({
        'id': -1,
        'content': content,
        'sender_id': widget.userId,
        'first_name': 'Вы',
        'last_name': '',
        'created_at': DateTime.now().toIso8601String(),
        'isTemp': true,
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final success = await DBService.sendMessage(widget.chatId, widget.userId, content);
      if (success && mounted) {
        await _loadMessages();
      } else if (mounted) {
        setState(() {
          if (tempIndex < _messages.length) _messages.removeAt(tempIndex);
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (tempIndex < _messages.length) _messages.removeAt(tempIndex);
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFullImage(String imageUrl) {
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

  Future<void> _openFile(String fileUrl, String fileName) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Icon _getFileIcon(String? fileName) {
    if (fileName == null) return const Icon(Icons.insert_drive_file, color: Colors.grey);
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx': return const Icon(Icons.description, color: Colors.blue);
      case 'xls':
      case 'xlsx': return const Icon(Icons.table_chart, color: Colors.green);
      case 'ppt':
      case 'pptx': return const Icon(Icons.slideshow, color: Colors.orange);
      case 'txt': return const Icon(Icons.text_snippet, color: Colors.grey);
      case 'zip':
      case 'rar':
      case '7z': return const Icon(Icons.folder_zip, color: Colors.purple);
      default: return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final utcDate = DateTime.parse(isoString);
      final localDate = utcDate.toLocal();
      return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _sendImageMessage() async {
    if (_selectedImageBytes == null || _selectedImageName == null) return;
    setState(() => _isUploading = true);
    try {
      final success = await DBService.sendImageMessage(
        widget.chatId,
        widget.userId,
        _selectedImageBytes!,
        _selectedImageName!,
      );
      if (success && mounted) {
        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
          _isUploading = false;
        });
        await _loadMessages();
        _scrollToBottom();
      } else if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить фото'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
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
        title: Text(widget.chatName),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ChatPopup(
                  chatId: widget.chatId,
                  chatName: widget.chatName,
                  currentUserId: widget.userId,
                  chatType: widget.chatType,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                : ListView.builder(
                    reverse: false,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == widget.userId;

                      final imageUrl = msg['image_url'] as String?;
                      final fileUrl = msg['file_url'] as String?;
                      final fileName = msg['file_name'] as String?;
                      final fileSize = msg['file_size'] as int?;

                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                      final hasFile = fileUrl != null && fileUrl.isNotEmpty && fileName != null;
                      final hasText = msg['content'] != null && msg['content'].toString().isNotEmpty;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFE53935) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                Text(
                                  '${msg['first_name'] ?? ''} ${msg['last_name'] ?? ''}'.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],

                              if (hasImage) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: GestureDetector(
                                    onTap: () => _showFullImage(imageUrl!),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                        maxWidth: double.infinity,
                                      ),
                                      child: Image.network(
                                        imageUrl!,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const SizedBox(
                                            height: 200,
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 150,
                                          alignment: Alignment.center,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasText) const SizedBox(height: 8),
                              ],

                              if (hasFile) ...[
                                GestureDetector(
                                  onTap: () => _openFile(fileUrl!, fileName!),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.white24 : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _getFileIcon(fileName),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fileName,
                                                style: TextStyle(
                                                  color: isMe ? Colors.white : Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (fileSize != null)
                                                Text(
                                                  _formatFileSize(fileSize),
                                                  style: TextStyle(
                                                    color: isMe ? Colors.white70 : Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.download,
                                          size: 20,
                                          color: isMe ? Colors.white70 : Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (hasText) const SizedBox(height: 8),
                              ],

                              if (hasText)
                                Text(
                                  msg['content'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),

                              if (msg['created_at'] != null) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _formatTime(msg['created_at']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_selectedImageBytes != null || _selectedFileBytes != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Stack(
                children: [
                  if (_selectedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 150,
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else if (_selectedFileBytes != null && _selectedFileName != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _getFileIcon(_selectedFileName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedFileName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedFileSize != null)
                                  Text(
                                    _formatFileSize(_selectedFileSize!),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _cancelSelection,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.attach_file, color: Color(0xFFE53935)),
                  onSelected: (value) {
                    if (value == 'image') _pickImage();
                    else if (value == 'file') _pickFile();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'image',
                      child: Row(children: [
                        Icon(Icons.photo_library, color: Color(0xFFE53935), size: 20),
                        SizedBox(width: 8),
                        Text('Фото'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'file',
                      child: Row(children: [
                        Icon(Icons.folder_open, color: Color(0xFFE53935), size: 20),
                        SizedBox(width: 8),
                        Text('Файл'),
                      ]),
                    ),
                  ],
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isSending && _selectedImageBytes == null && _selectedFileBytes == null && !_isUploading,
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) {
                      if (_selectedImageBytes != null) _sendImageMessage();
                      else if (_selectedFileBytes != null) _sendFileMessage();
                      else if (_controller.text.trim().isNotEmpty) _sendMessage();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _isSending || _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE53935),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFE53935)),
                        onPressed: () {
                          if (_selectedImageBytes != null) _sendImageMessage();
                          else if (_selectedFileBytes != null) _sendFileMessage();
                          else if (_controller.text.trim().isNotEmpty) _sendMessage();
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}