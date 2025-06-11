import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  LatLng? ubicacionUsuario;
  LatLng? ubicacionTienda;
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    obtenerUbicacionUsuario();
    obtenerUbicacionTienda();
  }

  Future<void> obtenerUbicacionUsuario() async {
    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) return;

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) return;
      }
      if (permiso == LocationPermission.deniedForever) return;

      Position posicion = await Geolocator.getCurrentPosition();
      setState(() {
        ubicacionUsuario = LatLng(posicion.latitude, posicion.longitude);
      });

      if (ubicacionTienda != null) obtenerRuta();
    } catch (e) {
      mostrarError('Error obteniendo tu ubicación');
    }
  }

  Future<void> obtenerUbicacionTienda() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tienda')
          .doc('principal')
          .get();

      final data = snapshot.data();
      if (data != null && data['tienda'] is GeoPoint) {
        final geo = data['tienda'] as GeoPoint;
        setState(() {
          ubicacionTienda = LatLng(geo.latitude, geo.longitude);
        });

        if (ubicacionUsuario != null) obtenerRuta();
      } else {
        mostrarError('Ubicación de la tienda no disponible');
      }
    } catch (e) {
      mostrarError('Error al obtener la ubicación de la tienda');
    }
  }

  Future<void> obtenerRuta() async {
    if (ubicacionUsuario == null || ubicacionTienda == null) return;

    final origen =
        "${ubicacionUsuario!.latitude},${ubicacionUsuario!.longitude}";
    final destino =
        "${ubicacionTienda!.latitude},${ubicacionTienda!.longitude}";

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/directions/json?origin=$origen&destination=$destino&key=$apiKey&mode=driving",
    );

    try {
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        final puntos = data["routes"][0]["overview_polyline"]["points"];
        final ruta = decodePolyline(puntos);
        setState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId("ruta"),
              color: const Color.fromARGB(255, 73, 167, 37),
              width: 5,
              points: ruta,
            ),
          };
        });
      } else {
        mostrarError('Error obteniendo la ruta (${respuesta.statusCode})');
      }
    } catch (e) {
      mostrarError('Error de red al obtener la ruta');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return polyline;
  }

  void mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cómo llegar a la tienda")),
      body: (ubicacionUsuario == null || ubicacionTienda == null)
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (ubicacionUsuario!.latitude + ubicacionTienda!.latitude) / 2,
                  (ubicacionUsuario!.longitude + ubicacionTienda!.longitude) / 2,
                ),
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('usuario'),
                  position: ubicacionUsuario!,
                  infoWindow: const InfoWindow(title: 'Tu ubicación'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
                Marker(
                  markerId: const MarkerId('tienda'),
                  position: ubicacionTienda!,
                  infoWindow: const InfoWindow(title: 'Panadería Delicia'),
                ),
              },
              polylines: polylines,
              onMapCreated: (controller) => mapController = controller,
            ),
    );
  }
}