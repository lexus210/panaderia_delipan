import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? imagenBase64;
  File? imagenSeleccionada;
  final picker = ImagePicker();

  String nombre = '';
  String correo = '';

  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    obtenerDatosUsuario();
  }

  Future<void> obtenerDatosUsuario() async {
    final user = auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        nombre = data['name'] ?? '';
        imagenBase64 = data['fotoPerfilBase64'];
        correo = user.email ?? '';
      });
    }
  }

  Future<void> seleccionarImagen(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 50);
    if (picked == null) return;

    setState(() {
      imagenSeleccionada = File(picked.path);
    });
  }

  Future<void> subirImagen() async {
    final user = auth.currentUser;
    if (user == null || imagenSeleccionada == null) return;

    final bytes = await imagenSeleccionada!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final docSnapshot = await docRef.get();

    await docRef.set({
      'fotoPerfilBase64': base64Image,
      'correo': user.email ?? '',
      'name': nombre,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      imagenBase64 = base64Image;
      imagenSeleccionada = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imagen de perfil actualizada')),
    );
  }

  Future<void> editarCampo({
    required String titulo,
    required String valorInicial,
    required Function(String) onGuardar,
    bool esPassword = false,
  }) async {
    final controller = TextEditingController(text: valorInicial);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar $titulo'),
        content: TextField(
          controller: controller,
          obscureText: esPassword,
          decoration: InputDecoration(
            labelText: titulo,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onGuardar(controller.text.trim());
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> actualizarNombre(String nuevoNombre) async {
    final user = auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .update({'name': nuevoNombre});

    setState(() {
      nombre = nuevoNombre;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nombre actualizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageWidget;

    if (imagenSeleccionada != null) {
      imageWidget = FileImage(imagenSeleccionada!);
    } else if (imagenBase64 != null) {
      try {
        final bytes = base64Decode(imagenBase64!);
        imageWidget = MemoryImage(bytes);
      } catch (e) {
        imageWidget = null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 70,
              backgroundImage: imageWidget,
              child:
                  imageWidget == null ? const Icon(Icons.person, size: 70) : null,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => seleccionarImagen(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text("Desde galería"),
                ),
                ElevatedButton.icon(
                  onPressed: () => seleccionarImagen(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Desde cámara"),
                ),
                if (imagenSeleccionada != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: subirImagen,
                    icon: const Icon(Icons.check),
                    label: const Text("Guardar imagen"),
                  ),
              ],
            ),
            const Divider(height: 40),
            _buildCampoEditable("Nombre", nombre, () {
              editarCampo(
                titulo: "Nombre",
                valorInicial: nombre,
                onGuardar: actualizarNombre,
              );
            }),
            _buildCampoNoEditable("Correo", correo),
            _buildCampoNoEditable("Contraseña", "********"),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoEditable(String label, String valor, VoidCallback onEdit) {
    return ListTile(
      title: Text(label),
      subtitle: Text(valor),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onEdit,
      ),
    );
  }

  Widget _buildCampoNoEditable(String label, String valor) {
    return ListTile(
      title: Text(label),
      subtitle: Text(valor, style: const TextStyle(color: Colors.grey)),
    );
  }
}