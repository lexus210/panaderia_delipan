import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Debe iniciar sesión para ver el historial',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final historialRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('historial')
        .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Pedidos',
          style: TextStyle(
            fontFamily: 'DancingScript',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFD27C2C),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historialRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Ocurrió un error al cargar los datos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay pedidos en el historial',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pedido = docs[index];
              final data = pedido.data() as Map<String, dynamic>? ?? {};

              final fechaTimestamp = data['fecha'] as Timestamp?;
              final fecha = fechaTimestamp != null
                  ? DateFormat('dd/MM/yyyy – HH:mm').format(fechaTimestamp.toDate())
                  : 'Fecha desconocida';

              final productos = data.containsKey('productos')
                  ? List<Map<String, dynamic>>.from(data['productos'] ?? [])
                  : <Map<String, dynamic>>[];

              final total = data.containsKey('total') ? (data['total'] as num?) ?? 0 : 0;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: Colors.orange.shade200,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.orange.shade50,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    title: Text(
                      'Pedido del $fecha',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.brown,
                      ),
                    ),
                    subtitle: Text(
                      'Total: ${currencyFormat.format(total)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD27C2C)),
                    children: productos.map((prod) {
                      final nombre = prod['nombre'] ?? 'Producto';
                      final precio = double.tryParse(prod['precio'].toString()) ?? 0.0;

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.local_dining, color: Colors.brown),
                        title: Text(nombre),
                        trailing: Text(
                          currencyFormat.format(precio),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}