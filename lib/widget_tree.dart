import 'package:flutter/material.dart';
import './pages/home_page.dart';
import './pages/login_register_page.dart';
import './controllers/auth_controller.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  final AuthController _authController = AuthController();

  @override
  // Monitor auth state real time and emit events to change screen
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authController.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return const LoginRegisterPage();
        }
      },
    );
  }
}