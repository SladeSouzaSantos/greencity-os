import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/obstacle_config.dart';
import 'package:greencity_os/domain/services/hsp_input_validator.dart';

void main() {
  test('aceita números com vírgula e rejeita valores não finitos', () {
    expect(HspInputValidator.parseNumber(' 2,75 '), 2.75);
    expect(HspInputValidator.parseNumber('NaN'), isNull);
    expect(HspInputValidator.parseNumber('Infinity'), isNull);
    expect(HspInputValidator.parseNumber(''), isNull);
  });

  test('largura e distância devem ser estritamente maiores que zero', () {
    expect(HspInputValidator.validateObstacleWidth('0'), isNotNull);
    expect(HspInputValidator.validateObstacleDistance('0,0'), isNotNull);
    expect(HspInputValidator.validateObstacleWidth('-1'), isNotNull);
    expect(HspInputValidator.validateObstacleWidth('2'), isNull);
    expect(HspInputValidator.validateObstacleDistance('5'), isNull);
  });

  test('altura do obstáculo aceita zero, conforme contrato da API', () {
    expect(HspInputValidator.validateObstacleHeight('0'), isNull);
    expect(HspInputValidator.validateObstacleHeight('-0,1'), isNotNull);
  });

  test('azimute entre 0 e 360, inclinação entre 0 e 90', () {
    expect(HspInputValidator.validateAzimuth('360'), isNull);
    expect(HspInputValidator.validateAzimuth('361'), isNotNull);
    expect(HspInputValidator.validateInclination('90'), isNull);
    expect(HspInputValidator.validateInclination('91'), isNotNull);
    expect(HspInputValidator.validateInclination('-1'), isNotNull);
  });

  test('quantidade inteira de 1 a 500 por conjunto', () {
    expect(HspInputValidator.validateQuantity('1'), isNull);
    expect(HspInputValidator.validateQuantity('500'), isNull);
    expect(HspInputValidator.validateQuantity('0'), isNotNull);
    expect(HspInputValidator.validateQuantity('501'), isNotNull);
    expect(HspInputValidator.validateQuantity('1.5'), isNotNull);
  });

  test('valida configuração de obstáculo para envio via repositório', () {
    final invalid = ObstacleConfig(
      height: 2,
      distance: 5,
      azimuthReference: 0,
      width: 0,
    );
    final valid = ObstacleConfig(
      height: 2,
      distance: 5,
      azimuthReference: 0,
      width: 2,
    );
    expect(HspInputValidator.validateObstacle(invalid), contains('Largura'));
    expect(HspInputValidator.validateObstacle(valid), isNull);
  });
}
