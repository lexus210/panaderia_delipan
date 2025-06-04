import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante de Pago')),
      body: Center(child: CustomButton(text: 'Ir a Sobre Nosotros', onPressed: () => Navigator.pushNamed(context, '/about'))),
    );
  }
}
