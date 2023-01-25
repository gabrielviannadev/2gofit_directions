import 'dart:async';
import 'package:flutter/material.dart';
import 'package:directions_2gofit/location_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2GOFit + Google Directions e Maps SDK',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

// Declarei a classe MapSampleState herdada do Google, e também instanciei as entradas de texto aonde o usuário digita o endereço de origem e saída.
class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

// Agora declarei e instanciei os marcadores "markers", os poligonos e polylines que irão comandar o traço de rotas do Google Directions pelas ruas.
  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polygonLatLngs = <LatLng>[];

  int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;

// Aqui coloquei a inicialização da câmera, suas coordenadas e o zoom. E depois setei um marker em cima dessa mesma localização.
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-23.530557, -46.728617),
    zoom: 18.0000,
  );

  @override
  void initState() {
    super.initState();

    _setMarker(LatLng(-23.530557, -46.728617));
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker'),
          position: point,
        ),
      );
    });
  }

// Aqui está instanciado um pequeno teste de polígonos.
  void _setPolygon() {
    final String polygonIdVal = 'polygon_$_polygonIdCounter';
    _polygonIdCounter++;

    _polygons.add(
      Polygon(
        polygonId: PolygonId(polygonIdVal),
        points: polygonLatLngs,
        strokeWidth: 0,
        fillColor: Colors.transparent,
      ),
    );
  }

// Aqui estão instaciodos os poligonos usados para traçar a rota que o app oferece ao apertar no botão.
  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$_polylineIdCounter';
    _polylineIdCounter++;
    _polylines.add(
      Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 6,
        color: Colors.deepPurple.shade900,
        points: points
            .map(
              (point) => LatLng(point.latitude, point.longitude),
            )
            .toList(),
      ),
    );
  }

// Aqui começa a ser construído o corpo do aplicativo, aonde apliquei as fontes, cores, containeirs, caixas de texto, entradas de texto, colunas e todos os outros widgets.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('2GOFit + Google Direction'),
        backgroundColor: Colors.deepPurple.shade900,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _originController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            hintText: '  Seu local de origem',
                            icon: Icon(Icons.gps_fixed)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            hintText: '  Endereço de destino completo',
                            helperText: 'Ex: Av. Paulista 3074, Bela Vista, São Paulo',
                            suffixIcon: Icon(Icons.location_on_outlined)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

// Aqui está instanciado o mapa do Google oferecido pela API, e suas configurações.
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: (point) {
                setState(
                  () {
                    polygonLatLngs.add(point);
                    _setPolygon();
                  },
                );
              },
            ),
          ),

// Por aqui o botão flutuante usado como função para calcular a rota, depois dos endereços terem sido colocados.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton.extended(
              extendedPadding: const EdgeInsets.all(8.0),
              label: const Text('Calcular minha rota'),
              icon: const Icon(Icons.route),
              backgroundColor: Colors.deepPurple.shade900,
              onPressed: () async {
                var directions = await LocationService().getDirections(
                  _originController.text,
                  _destinationController.text,
                );
                _goToPlace(
                  directions['start_location']['lat'],
                  directions['start_location']['lng'],
                  directions['bounds_ne'],
                  directions['bounds_sw'],
                );
                _setPolyline(directions['polyline_decoded']);
              },
            ),
          ),
          Container(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: RichText(
                text: TextSpan(
                  text: 'Versão 1.0 - gabrielviannadev',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Por último retorno a função e variáveis assincronas de goToPlace, e também instacionei a animação da câmera, para tirar o zoom quando apertamos no botão para mostrar a rota calculada.
  Future<void> _goToPlace(
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12),
      ),
    );
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
          ),
          25),
    );
    _setMarker(LatLng(lat, lng));
  }
}
