import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carrito_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  List<Map<String, dynamic>> carrito = [];
  TextEditingController searchController = TextEditingController();
  late AnimationController _iconAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    obtenerProductos();

    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  Future<void> obtenerProductos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();

      final lista =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      if (!mounted) return;
      setState(() {
        productos = lista;
        productosFiltrados = lista;
      });
    } catch (e) {
      print('Error al obtener productos: $e');
    }
  }

  void filtrarProductos(String texto) {
    final resultado =
        productos.where((producto) {
          final nombre = producto['nombre']?.toLowerCase() ?? '';
          return nombre.startsWith(texto.trim().toLowerCase());
        }).toList();

    setState(() {
      productosFiltrados = resultado;
    });
  }

  void agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      carrito.add(producto);
    });

    _iconAnimationController.forward().then((_) {
      _iconAnimationController.reverse();
    });

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      content: Text('${producto['nombre']} añadido al carrito'),
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void irAlCarrito() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CarritoScreen(carrito: carrito)),
    );
    if (!mounted) return;
    setState(() {});
  }

  void cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: const Text('Se cerrará tu sesión actual.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
          255,
          196,
          109,
          4,
        ), // Color cálido de panadería
        title: const Text(
          'Panadería Delicia',
          style: TextStyle(
            fontFamily: 'DancingScript', // Fuente amigable de panadería
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: cerrarSesion,
          ),
          Stack(
            children: [
              IconButton(
                icon: ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(Icons.shopping_cart),
                ),
                onPressed: irAlCarrito,
              ),
              if (carrito.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${carrito.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: filtrarProductos,
              decoration: InputDecoration(
                labelText: 'Buscar pan o pastel...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.brown[50], // Fondo beige claro
              ),
            ),
          ),
          Expanded(
            child:
                productosFiltrados.isEmpty
                    ? const Center(child: Text('No se encontraron productos'))
                    : ListView.builder(
                      itemCount: productosFiltrados.length,
                      itemBuilder: (context, index) {
                        final producto = productosFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          color:
                              Colors
                                  .brown[100], // Fondo cálido para cada producto
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: producto['imagenUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    producto['imagenUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.broken_image, color: Colors.grey);
                                    },
                                  ),
                                )
                              : Icon(Icons.bakery_dining, color: Colors.brown[700]),
                            title: Text(
                              producto['nombre'] ?? 'Sin nombre',
                              style: TextStyle(
                                fontFamily: 'DancingScript', // Fuente amigable
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'S/ ${producto['precio'] ?? '0.00'}',
                              style: TextStyle(
                                color: Colors.brown[600], // Color del precio
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  211,
                                  132,
                                  42,
                                ), // Color cálido
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => agregarAlCarrito(producto),
                              child: const Text('Agregar'),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}