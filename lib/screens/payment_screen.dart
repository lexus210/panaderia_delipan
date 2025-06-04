import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de Pago')),
      body: Center(child: CustomButton(text: 'Ir a Seguimiento', onPressed: () => Navigator.pushNamed(context, '/tracking'))),
    );
  }
}
