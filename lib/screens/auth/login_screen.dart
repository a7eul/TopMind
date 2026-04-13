import 'package:flutter/material.dart';
import '../../services/db_service.dart';  
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {  
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      backgroundColor: const Color(0xFFF0FFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Логотип TOP Mind
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOP',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 28,
                        margin: const EdgeInsets.only(left: 4, top: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mind',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 50),
              
              // Белая карточка с полями
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
                    // Поле Логин 
                    _buildTextField(
                      controller: loginController,  
                      label: 'Логин',
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.text,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Поле Пароль ← С КОНТРОЛЛЕРОМ!
                    _buildTextField(
                      controller: passController,
                      label: 'Пароль',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Кнопка Войти ← С БАЗОЙ!
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    print('🔄 Логин: ${loginController.text}');
                    final user = await DBService.login(
                      loginController.text, 
                      passController.text
                    );
                    print('👤 Результат: $user');
                    
                    if (user != null) {
                      Navigator.pushReplacementNamed(context, '/main');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Неправильный логин/пароль'))
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
                    'Войти',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Переход на регистрацию
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Нет аккаунта? Зарегистрироваться',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,  
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,  
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE53935)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}