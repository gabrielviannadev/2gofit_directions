// Primeiros vamos instanciar as importações usadas, polyline para traçarmos as rotas com poligonos, http para importarmos os endereços do Google e o convert para convertermos as coordenadas.
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

// Agora declarei a classe de localização e instanciei a Key que gerei no meu Google Cloud Console (gabriel.skararmy192@gmail.com).
// Vale ressaltar que tive que aplicar algumas restrições na Key, como o directions_api, google_places, google_roads e google_maps_sdk para puxarmos todos os dados que precisamos.
// Usando também uma variável $key para toda vez que precisar colar a minha Key do Google Cloud.
class LocationService {
  final String key = 'AIzaSyDoOryVGooR7KW37r8Ao_CxD8xKD6X30XY';

// Aqui instanciei algumas url's com dados dos locais do Google, via http, como informado no documento de referência do Google, assim como vou fazer outras vezes e uma INPUT em formato STRING, com função assincrona.
// Também foram usados alguns parâmetros em JavaScript para decodificação e conversão do lado do cliente.
  Future<String> getPlaceId(String input) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var placeId = json['candidatos'][0]['lugar_id'] as String;

    return placeId;
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeId = await getPlaceId(input);

    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['resultado'] as Map<String, dynamic>;
    return results;
  }

// A partir daqui instanciei duas variáveis $origin e $destination para que fosse maleáveis ao link http do Google Directions, conforme o documento de orientação da API.
  Future<Map<String, dynamic>> getDirections(String origin, String destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);

// Aqui está declarada uma variável de resultado com as "routes" rotas, a bússola, o ponto de início e fim do trajeto, e todos os parâmetros do trajeto.
// Também há declarações das polylines, que são os polígonos usados para traçar a rota entre as ruas no mapa.
// Essa parte envolveu JavaScript também.
    var results = {
      'bounds_ne': json['routes'][0]['bounds']['northeast'],
      'bounds_sw': json['routes'][0]['bounds']['southwest'],
      'start_location': json['routes'][0]['legs'][0]['start_location'],
      'end_location': json['routes'][0]['legs'][0]['end_location'],
      'polyline': json['routes'][0]['overview_polyline']['points'],
      'polyline_decoded': PolylinePoints().decodePolyline(json['routes'][0]['overview_polyline']['points']),
    };
    return results;
  }
}
