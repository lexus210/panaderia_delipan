import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de Compras')),
      body: Center(
        child: CustomButton(
          text: 'Ir a Pago',
          onPressed: () => Navigator.pushNamed(context, '/payment'),
        ),
      ),
    );
  }
}
