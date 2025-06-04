import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento del Pedido')),
      body: Center(child: CustomButton(text: 'Ir al Comprobante', onPressed: () => Navigator.pushNamed(context, '/receipt'))),
    );
  }
}
