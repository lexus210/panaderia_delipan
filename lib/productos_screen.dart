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
      final lista = snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
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
    final resultado = productos.where((producto) {
      final nombre = producto['nombre']?.toLowerCase() ?? '';
      return nombre.contains(texto.trim().toLowerCase());
    }).toList();
    setState(() {
      productosFiltrados = resultado;
    });
  }

  void agregarAlCarrito(Map<String, dynamic> producto) {
    final yaExiste = carrito.any((item) => item['id'] == producto['id']);
    if (yaExiste) return;
    setState(() {
      carrito.add(producto);
    });
    _iconAnimationController.forward().then((_) {
      _iconAnimationController.reverse();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        content: Text('${producto['nombre']} añadido al carrito'),
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
      builder: (_) => AlertDialog(
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
        backgroundColor: const Color(0xFFD27C2C),
        title: const Text(
          'Panadería Delicia',
          style: TextStyle(
            fontFamily: 'DancingScript',
            fontSize: 26,
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
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${carrito.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                labelText: 'Buscar productos...'
                    .toUpperCase(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.orange[50],
              ),
            ),
          ),
          Expanded(
            child: productosFiltrados.isEmpty
                ? const Center(child: Text('No se encontraron productos'))
                : ListView.builder(
                    itemCount: productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = productosFiltrados[index];
                      final nombre = producto['nombre'] ?? 'Sin nombre';
                      final precio = producto['precio'] ?? 0.0;
                      final imagenUrl = producto['imagenUrl'];
                      final descripcion = producto['descripcion'] ?? '';

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        color: Colors.brown[50],
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imagenUrl != null && imagenUrl.toString().contains('http')
                                ? Image.network(
                                    imagenUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.bakery_dining),
                          ),
                          title: Text(nombre,
                              style: const TextStyle(
                                  fontFamily: 'DancingScript',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                descripcion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.brown[700]),
                              ),
                              Text(
                                'S/ ${precio.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.brown[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD27C2C),
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