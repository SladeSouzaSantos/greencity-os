import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/openrouter_datasheet_service.dart';

void main() {
  const primary = 'nvidia/nemotron-3.5-super-vl:free';
  late Directory temp;
  late File pdf;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('inverter_refinement_');
    pdf = File('${temp.path}/datasheet.pdf');
    await pdf.writeAsString('%PDF-1.4\n% in-memory test\n');
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  Map<String, dynamic> completion(Map<String, dynamic> result,
      {List<dynamic>? annotations}) => {
    'choices': [
      {'finish_reason': 'stop', 'message': {
        'role': 'assistant', 'content': jsonEncode(result),
        if (annotations != null) 'annotations': annotations,
      }},
    ],
  };

  OpenRouterDatasheetService service(Dio dio) => OpenRouterDatasheetService(
    dio: dio, apiKey: 'test', model: primary,
    fallbackModels: '', pdfEngine: 'cloudflare-ai',
  );

  test('segunda leitura usa só texto das annotations, sem PDF/Base64', () async {
    final dio = Dio();
    final bodies = <Map>[];
    final docText = [
      'Ficha técnica Solplanet',
      'Modelo ASW7300-S e ASW9100-S',
      'Potência ativa nominal: 7300 W / 9100 W',
      'Potência máxima matriz: 13200 Wp / 16500 Wp',
      'Tensão máxima entrada 600 V',
      'Faixa MPPT 80-560V / 360V, 3/1 MPPTs',
      'Correntes: 16A/16A/16A e 20A/16A/20A',
    ].join('\n');
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final body = options.data as Map;
      bodies.add(body);
      final response = bodies.length == 1
          ? completion({'modules': [], 'inverters': [{
              'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
              'nominalPowerKw': 9.1, 'mpptCount': 3,
            }]}, annotations: [{
              'type': 'file',
              'file': {'content': [{'type': 'text', 'text': docText}]},
            }])
          : completion({'modules': [], 'inverters': [{
              'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
              'nominalPowerKw': 9.1, 'maxInputPowerWp': 16500,
              'maxInputVoltage': 600, 'mpptVoltageRange': '80V-560V/360V',
              'maxInputCurrentPerMppt': '20A/16A/20A', 'mpptCount': 3,
            },{
              'manufacturer': 'Solplanet', 'modelName': 'ASW7300-S',
              'nominalPowerKw': 7.3, 'maxInputPowerWp': 13200,
            }]});
      handler.resolve(Response(
        requestOptions: options, statusCode: 200, data: response,
      ));
    }));
    final result = await service(dio).extractEquipmentData(pdf.path);
    expect(bodies, hasLength(2));
    expect(bodies.first.containsKey('plugins'), isTrue);
    expect(bodies.last.containsKey('plugins'), isFalse);
    final content = (bodies.last['messages'] as List).first['content'] as List;
    expect(content, hasLength(1));
    expect(content.first['type'], 'text');
    expect(jsonEncode(bodies.last), isNot(contains('application/pdf;base64')));
    expect(result.inverters, hasLength(2));
    expect(result.inverters.first.nominalPowerKw, 9.1);
    expect(result.inverters.first.maxInputPowerKw, 16.5);
    expect(result.inverters.first.mpptInputCurrentsA, [20,16,20]);
  });

  test('enriquece módulo incompleto sem retransmitir PDF', () async {
    final dio = Dio();
    final requests = <Map>[];
    final docText = List.filled(3,
      'Ficha técnica Jetion JT-700 STC 700 Wp; Vmp 41 V; '
      'Voc 49.5 V; comprimento 2382 mm; tecnologia TOPCON.'
    ).join(' ');
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options.data as Map);
      handler.resolve(Response(
        requestOptions: options, statusCode: 200,
        data: requests.length == 1
          ? completion({'modules': [{
              'manufacturer': 'Jetion', 'modelName': 'JT-700',
              'powerWp': 700,
            }], 'inverters': []}, annotations: [{
              'type': 'file', 'file': {'content': [
                {'type': 'text', 'text': docText},
              ]},
            }])
          : completion({'modules': [{
              'manufacturer': 'Jetion', 'modelName': 'JT-700',
              'powerWp': 705, 'vMp': 41, 'vOc': 49.5,
              'length': 2382, 'cellTechnology': 'TOPCON',
            }], 'inverters': []}),
      ));
    }));
    final result = await service(dio).extractEquipmentData(pdf.path);
    expect(requests, hasLength(2));
    expect(requests.last.containsKey('plugins'), isFalse);
    expect(result.modules.single.powerWp, 700);
    expect(result.modules.single.vMp, 41);
    expect(result.modules.single.length, 2382);
  });

  test('sem annotations retorna extração inicial sem novo envio', () async {
    final dio = Dio();
    var count = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      count++;
      handler.resolve(Response(
        requestOptions: options, statusCode: 200,
        data: completion({'modules': [], 'inverters': [{
          'manufacturer': 'Solplanet',
          'modelName': 'ASW7300-S',
          'nominalPowerKw': 7.3,
        }]}),
      ));
    }));
    final result = await service(dio).extractEquipmentData(pdf.path);
    expect(count, 1);
    expect(result.inverters.single.nominalPowerKw, 7.3);
  });
}
