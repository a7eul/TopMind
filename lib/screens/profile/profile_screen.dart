import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data'; 
import 'package:image_picker/image_picker.dart';
import '../../services/db_service.dart';
import '../widgets/side_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isEditing = false;

  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
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

      if (mounted) {
        setState(() {
          _user = user;
          _nameController.text = user['first_name'] ?? '';
          _surnameController.text = user['last_name'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null || !mounted) return;

    try {
      final success = await DBService.updateProfile(
        _user!['id'],
        _nameController.text,
        _surnameController.text,
      );

      if (success && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final updatedUser = Map<String, dynamic>.from(_user!)
          ..['first_name'] = _nameController.text
          ..['last_name'] = _surnameController.text;
        await prefs.setString('current_user', jsonEncode(updatedUser));

        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось обновить профиль')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _editProfile() {
    if (mounted) setState(() => _isEditing = true);
  }

  void _logout() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('current_user');
              Navigator.pop(context);
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
  Future<void> _changeAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    try {
      setState(() => _isLoading = true);

      final Uint8List bytes = await pickedFile.readAsBytes();

      final newAvatarUrl = await DBService.uploadAvatar(
        _user!['id'],
        bytes,
        pickedFile.name,
      );

      if (mounted && newAvatarUrl != null) {
        setState(() {
          _user!['avatar_url'] = newAvatarUrl;
          _isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(_user));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар обновлен'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
      );
    }

    final avatarUrl = _user?['avatar_url'] as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Профиль',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFE0E0E0),
                                ),
                                child: ClipOval(
                                  child: hasAvatar
                                      ? Image.network(
                                          avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: const Color(0xFFE0E0E0),
                                            child: const Icon(Icons.person, size: 50, color: Color(0xFF9E9E9E)),
                                          ),
                                        )
                                      : const Icon(Icons.person, size: 50, color: Color(0xFF9E9E9E)),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _changeAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: const Color(0xFFE0E0E0))),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Данные', style: TextStyle(color: Color(0xFF757575), fontSize: 14))),
                              Expanded(child: Container(height: 1, color: const Color(0xFFE0E0E0))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Имя',
                            icon: Icons.person_outline,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _surnameController,
                            label: 'Фамилия',
                            icon: Icons.badge_outlined,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _logout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Выйти', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isEditing ? _saveProfile : _editProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEditing ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                                    foregroundColor: _isEditing ? Colors.white : const Color(0xFF212121),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(_isEditing ? 'Сохранить' : 'Редактировать', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(margin: const EdgeInsets.only(right: 12), child: const SideMenu(activeIndex: 0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE53935)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: enabled ? const Color(0xFFF5F5F5) : const Color(0xFFEEEEEE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}