import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // No redirigimos aquí. El StreamBuilder en main.dart lo hará automáticamente.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // Después del registro exitoso, deja que Firebase lo detecte y redirija.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo')),
          TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: login, child: const Text("Ingresar")),
          TextButton(onPressed: register, child: const Text("Registrarse")),
        ]),
      ),
    );
  }
}
