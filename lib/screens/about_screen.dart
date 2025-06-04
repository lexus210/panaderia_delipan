import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre Nosotros')),
      body: Center(child: CustomButton(text: 'Volver a Login', onPressed: () => Navigator.pushNamed(context, '/login'))),
    );
  }
}
