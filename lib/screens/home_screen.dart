import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String convertDriveLinkToDirect(String driveLink) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(driveLink);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    } else {
      return driveLink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Productos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('productos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error cargando productos.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final productos = snapshot.data!.docs.map((doc) => Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return Card(
                child: ListTile(
                  leading: Image.network(producto.imagenUrl, width: 60, fit: BoxFit.cover),
                  title: Text(producto.nombre),
                  subtitle: Text('${producto.descripcion}\nS/ ${producto.precio.toStringAsFixed(2)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      // Aquí luego agregamos al carrito
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${producto.nombre} agregado al carrito')));
                    },
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
