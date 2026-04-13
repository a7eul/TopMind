import 'package:flutter/material.dart';
import '../../services/db_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      backgroundColor: const Color(0xFFF0FFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              const Text(
                'Регистрация',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildTextField(
                      controller: firstNameController,
                      label: 'Имя',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: lastNameController,
                      label: 'Фамилия',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: loginController,
                      label: 'Логин',
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: passwordController,
                      label: 'Пароль',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: confirmPasswordController,
                      label: 'Подтвердите пароль',
                      icon: Icons.lock_reset,
                      isPassword: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (passwordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Пароли не совпадают!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    print('Регистрация: ${loginController.text}');
                    
                    final success = await DBService.register(
                      firstNameController.text,
                      lastNameController.text,
                      loginController.text,
                      passwordController.text,
                    );
                    
                    print('Результат: $success');

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Регистрация успешна!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Логин уже существует!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 15),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Уже есть аккаунт? Войти',
                  style: TextStyle(color: Color(0xFFE53935), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE53935)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}