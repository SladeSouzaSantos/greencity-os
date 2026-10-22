// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inverter.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInverterCollection on Isar {
  IsarCollection<Inverter> get inverters => this.collection();
}

const InverterSchema = CollectionSchema(
  name: r'Inverter',
  id: -4468946845546290087,
  properties: {
    r'dimensions': PropertySchema(
      id: 0,
      name: r'dimensions',
      type: IsarType.string,
    ),
    r'euroEfficiency': PropertySchema(
      id: 1,
      name: r'euroEfficiency',
      type: IsarType.double,
    ),
    r'gridConnection': PropertySchema(
      id: 2,
      name: r'gridConnection',
      type: IsarType.byte,
      enumMap: _InvertergridConnectionEnumValueMap,
    ),
    r'inverterType': PropertySchema(
      id: 3,
      name: r'inverterType',
      type: IsarType.byte,
      enumMap: _InverterinverterTypeEnumValueMap,
    ),
    r'isHybrid': PropertySchema(
      id: 4,
      name: r'isHybrid',
      type: IsarType.bool,
    ),
    r'manufacturer': PropertySchema(
      id: 5,
      name: r'manufacturer',
      type: IsarType.string,
    ),
    r'maxEfficiency': PropertySchema(
      id: 6,
      name: r'maxEfficiency',
      type: IsarType.double,
    ),
    r'maxInputCurrentPerMppt': PropertySchema(
      id: 7,
      name: r'maxInputCurrentPerMppt',
      type: IsarType.double,
    ),
    r'maxInputPowerKw': PropertySchema(
      id: 8,
      name: r'maxInputPowerKw',
      type: IsarType.double,
    ),
    r'maxInputVoltage': PropertySchema(
      id: 9,
      name: r'maxInputVoltage',
      type: IsarType.double,
    ),
    r'maxMpptVoltage': PropertySchema(
      id: 10,
      name: r'maxMpptVoltage',
      type: IsarType.double,
    ),
    r'maxOperatingTemp': PropertySchema(
      id: 11,
      name: r'maxOperatingTemp',
      type: IsarType.double,
    ),
    r'maxOutputCurrent': PropertySchema(
      id: 12,
      name: r'maxOutputCurrent',
      type: IsarType.double,
    ),
    r'maxShortCircuitCurrent': PropertySchema(
      id: 13,
      name: r'maxShortCircuitCurrent',
      type: IsarType.double,
    ),
    r'minMpptVoltage': PropertySchema(
      id: 14,
      name: r'minMpptVoltage',
      type: IsarType.double,
    ),
    r'minOperatingTemp': PropertySchema(
      id: 15,
      name: r'minOperatingTemp',
      type: IsarType.double,
    ),
    r'modelName': PropertySchema(
      id: 16,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'mpptCount': PropertySchema(
      id: 17,
      name: r'mpptCount',
      type: IsarType.long,
    ),
    r'nominalPowerKw': PropertySchema(
      id: 18,
      name: r'nominalPowerKw',
      type: IsarType.double,
    ),
    r'nominalVoltageAc': PropertySchema(
      id: 19,
      name: r'nominalVoltageAc',
      type: IsarType.double,
    ),
    r'nominalVoltageDc': PropertySchema(
      id: 20,
      name: r'nominalVoltageDc',
      type: IsarType.double,
    ),
    r'protectionDegree': PropertySchema(
      id: 21,
      name: r'protectionDegree',
      type: IsarType.string,
    ),
    r'startVoltage': PropertySchema(
      id: 22,
      name: r'startVoltage',
      type: IsarType.double,
    ),
    r'warrantyYears': PropertySchema(
      id: 23,
      name: r'warrantyYears',
      type: IsarType.long,
    ),
    r'weight': PropertySchema(
      id: 24,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _inverterEstimateSize,
  serialize: _inverterSerialize,
  deserialize: _inverterDeserialize,
  deserializeProp: _inverterDeserializeProp,
  idName: r'id',
  indexes: {
    r'manufacturer': IndexSchema(
      id: -7451030802822204164,
      name: r'manufacturer',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'manufacturer',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _inverterGetId,
  getLinks: _inverterGetLinks,
  attach: _inverterAttach,
  version: '3.1.0+1',
);

int _inverterEstimateSize(
  Inverter object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dimensions.length * 3;
  bytesCount += 3 + object.manufacturer.length * 3;
  bytesCount += 3 + object.modelName.length * 3;
  bytesCount += 3 + object.protectionDegree.length * 3;
  return bytesCount;
}

void _inverterSerialize(
  Inverter object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dimensions);
  writer.writeDouble(offsets[1], object.euroEfficiency);
  writer.writeByte(offsets[2], object.gridConnection.index);
  writer.writeByte(offsets[3], object.inverterType.index);
  writer.writeBool(offsets[4], object.isHybrid);
  writer.writeString(offsets[5], object.manufacturer);
  writer.writeDouble(offsets[6], object.maxEfficiency);
  writer.writeDouble(offsets[7], object.maxInputCurrentPerMppt);
  writer.writeDouble(offsets[8], object.maxInputPowerKw);
  writer.writeDouble(offsets[9], object.maxInputVoltage);
  writer.writeDouble(offsets[10], object.maxMpptVoltage);
  writer.writeDouble(offsets[11], object.maxOperatingTemp);
  writer.writeDouble(offsets[12], object.maxOutputCurrent);
  writer.writeDouble(offsets[13], object.maxShortCircuitCurrent);
  writer.writeDouble(offsets[14], object.minMpptVoltage);
  writer.writeDouble(offsets[15], object.minOperatingTemp);
  writer.writeString(offsets[16], object.modelName);
  writer.writeLong(offsets[17], object.mpptCount);
  writer.writeDouble(offsets[18], object.nominalPowerKw);
  writer.writeDouble(offsets[19], object.nominalVoltageAc);
  writer.writeDouble(offsets[20], object.nominalVoltageDc);
  writer.writeString(offsets[21], object.protectionDegree);
  writer.writeDouble(offsets[22], object.startVoltage);
  writer.writeLong(offsets[23], object.warrantyYears);
  writer.writeDouble(offsets[24], object.weight);
}

Inverter _inverterDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Inverter(
    dimensions: reader.readString(offsets[0]),
    euroEfficiency: reader.readDouble(offsets[1]),
    gridConnection: _InvertergridConnectionValueEnumMap[
            reader.readByteOrNull(offsets[2])] ??
        GridConnection.monophasic,
    inverterType:
        _InverterinverterTypeValueEnumMap[reader.readByteOrNull(offsets[3])] ??
            InverterType.string,
    isHybrid: reader.readBool(offsets[4]),
    manufacturer: reader.readString(offsets[5]),
    maxEfficiency: reader.readDouble(offsets[6]),
    maxInputCurrentPerMppt: reader.readDouble(offsets[7]),
    maxInputPowerKw: reader.readDouble(offsets[8]),
    maxInputVoltage: reader.readDouble(offsets[9]),
    maxMpptVoltage: reader.readDouble(offsets[10]),
    maxOperatingTemp: reader.readDouble(offsets[11]),
    maxOutputCurrent: reader.readDouble(offsets[12]),
    maxShortCircuitCurrent: reader.readDouble(offsets[13]),
    minMpptVoltage: reader.readDouble(offsets[14]),
    minOperatingTemp: reader.readDouble(offsets[15]),
    modelName: reader.readString(offsets[16]),
    mpptCount: reader.readLong(offsets[17]),
    nominalPowerKw: reader.readDouble(offsets[18]),
    nominalVoltageAc: reader.readDouble(offsets[19]),
    nominalVoltageDc: reader.readDouble(offsets[20]),
    protectionDegree: reader.readString(offsets[21]),
    startVoltage: reader.readDouble(offsets[22]),
    warrantyYears: reader.readLongOrNull(offsets[23]) ?? 10,
    weight: reader.readDouble(offsets[24]),
  );
  object.id = id;
  return object;
}

P _inverterDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (_InvertergridConnectionValueEnumMap[
              reader.readByteOrNull(offset)] ??
          GridConnection.monophasic) as P;
    case 3:
      return (_InverterinverterTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          InverterType.string) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readDouble(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readDouble(offset)) as P;
    case 23:
      return (reader.readLongOrNull(offset) ?? 10) as P;
    case 24:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _InvertergridConnectionEnumValueMap = {
  'monophasic': 0,
  'biphasic': 1,
  'triphasic': 2,
};
const _InvertergridConnectionValueEnumMap = {
  0: GridConnection.monophasic,
  1: GridConnection.biphasic,
  2: GridConnection.triphasic,
};
const _InverterinverterTypeEnumValueMap = {
  'string': 0,
  'microInverter': 1,
  'optimizer': 2,
};
const _InverterinverterTypeValueEnumMap = {
  0: InverterType.string,
  1: InverterType.microInverter,
  2: InverterType.optimizer,
};

Id _inverterGetId(Inverter object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _inverterGetLinks(Inverter object) {
  return [];
}

void _inverterAttach(IsarCollection<dynamic> col, Id id, Inverter object) {
  object.id = id;
}

extension InverterQueryWhereSort on QueryBuilder<Inverter, Inverter, QWhere> {
  QueryBuilder<Inverter, Inverter, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InverterQueryWhere on QueryBuilder<Inverter, Inverter, QWhereClause> {
  QueryBuilder<Inverter, Inverter, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterWhereClause> manufacturerEqualTo(
      String manufacturer) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'manufacturer',
        value: [manufacturer],
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterWhereClause> manufacturerNotEqualTo(
      String manufacturer) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manufacturer',
              lower: [],
              upper: [manufacturer],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manufacturer',
              lower: [manufacturer],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manufacturer',
              lower: [manufacturer],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'manufacturer',
              lower: [],
              upper: [manufacturer],
              includeUpper: false,
            ));
      }
    });
  }
}

extension InverterQueryFilter
    on QueryBuilder<Inverter, Inverter, QFilterCondition> {
  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dimensions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dimensions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dimensions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dimensions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dimensions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dimensions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dimensions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dimensions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> dimensionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dimensions',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      dimensionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dimensions',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> euroEfficiencyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'euroEfficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      euroEfficiencyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'euroEfficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      euroEfficiencyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'euroEfficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> euroEfficiencyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'euroEfficiency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> gridConnectionEqualTo(
      GridConnection value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gridConnection',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      gridConnectionGreaterThan(
    GridConnection value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gridConnection',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      gridConnectionLessThan(
    GridConnection value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gridConnection',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> gridConnectionBetween(
    GridConnection lower,
    GridConnection upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gridConnection',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> inverterTypeEqualTo(
      InverterType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inverterType',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      inverterTypeGreaterThan(
    InverterType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inverterType',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> inverterTypeLessThan(
    InverterType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inverterType',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> inverterTypeBetween(
    InverterType lower,
    InverterType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inverterType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> isHybridEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isHybrid',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> manufacturerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manufacturer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      manufacturerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'manufacturer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> manufacturerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'manufacturer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> manufacturerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'manufacturer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      manufacturerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'manufacturer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> manufacturerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'manufacturer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> manufacturerContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'manufacturer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> manufacturerMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'manufacturer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      manufacturerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manufacturer',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      manufacturerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'manufacturer',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> maxEfficiencyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxEfficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxEfficiencyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxEfficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> maxEfficiencyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxEfficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> maxEfficiencyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxEfficiency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputCurrentPerMpptEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxInputCurrentPerMppt',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputCurrentPerMpptGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxInputCurrentPerMppt',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputCurrentPerMpptLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxInputCurrentPerMppt',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputCurrentPerMpptBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxInputCurrentPerMppt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputPowerKwEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxInputPowerKw',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputPowerKwGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxInputPowerKw',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputPowerKwLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxInputPowerKw',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputPowerKwBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxInputPowerKw',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputVoltageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxInputVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputVoltageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxInputVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputVoltageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxInputVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxInputVoltageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxInputVoltage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> maxMpptVoltageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxMpptVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxMpptVoltageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxMpptVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxMpptVoltageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxMpptVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> maxMpptVoltageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxMpptVoltage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOperatingTempEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxOperatingTemp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOperatingTempGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxOperatingTemp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOperatingTempLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxOperatingTemp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOperatingTempBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxOperatingTemp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOutputCurrentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxOutputCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOutputCurrentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxOutputCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOutputCurrentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxOutputCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxOutputCurrentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxOutputCurrent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxShortCircuitCurrentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxShortCircuitCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxShortCircuitCurrentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxShortCircuitCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxShortCircuitCurrentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxShortCircuitCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      maxShortCircuitCurrentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxShortCircuitCurrent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> minMpptVoltageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minMpptVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      minMpptVoltageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minMpptVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      minMpptVoltageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minMpptVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> minMpptVoltageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minMpptVoltage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      minOperatingTempEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minOperatingTemp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      minOperatingTempGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minOperatingTemp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      minOperatingTempLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minOperatingTemp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      minOperatingTempBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minOperatingTemp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modelName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modelName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> mpptCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mpptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> mpptCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mpptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> mpptCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mpptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> mpptCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mpptCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> nominalPowerKwEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nominalPowerKw',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalPowerKwGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nominalPowerKw',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalPowerKwLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nominalPowerKw',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> nominalPowerKwBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nominalPowerKw',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageAcEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nominalVoltageAc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageAcGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nominalVoltageAc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageAcLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nominalVoltageAc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageAcBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nominalVoltageAc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageDcEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nominalVoltageDc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageDcGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nominalVoltageDc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageDcLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nominalVoltageDc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      nominalVoltageDcBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nominalVoltageDc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protectionDegree',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protectionDegree',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protectionDegree',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protectionDegree',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'protectionDegree',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'protectionDegree',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'protectionDegree',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'protectionDegree',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protectionDegree',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      protectionDegreeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'protectionDegree',
        value: '',
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> startVoltageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      startVoltageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> startVoltageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> startVoltageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startVoltage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> warrantyYearsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warrantyYears',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition>
      warrantyYearsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'warrantyYears',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> warrantyYearsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'warrantyYears',
        value: value,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> warrantyYearsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'warrantyYears',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> weightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> weightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> weightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterFilterCondition> weightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension InverterQueryObject
    on QueryBuilder<Inverter, Inverter, QFilterCondition> {}

extension InverterQueryLinks
    on QueryBuilder<Inverter, Inverter, QFilterCondition> {}

extension InverterQuerySortBy on QueryBuilder<Inverter, Inverter, QSortBy> {
  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByDimensions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dimensions', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByDimensionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dimensions', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByEuroEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'euroEfficiency', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByEuroEfficiencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'euroEfficiency', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByGridConnection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridConnection', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByGridConnectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridConnection', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByInverterType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inverterType', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByInverterTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inverterType', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByIsHybrid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHybrid', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByIsHybridDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHybrid', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByManufacturer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByManufacturerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxEfficiency', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxEfficiencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxEfficiency', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      sortByMaxInputCurrentPerMppt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputCurrentPerMppt', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      sortByMaxInputCurrentPerMpptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputCurrentPerMppt', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxInputPowerKw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputPowerKw', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxInputPowerKwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputPowerKw', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxInputVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxInputVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxMpptVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxMpptVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxMpptVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxMpptVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxOutputCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOutputCurrent', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMaxOutputCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOutputCurrent', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      sortByMaxShortCircuitCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxShortCircuitCurrent', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      sortByMaxShortCircuitCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxShortCircuitCurrent', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMinMpptVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minMpptVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMinMpptVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minMpptVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMinOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMinOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMpptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mpptCount', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByMpptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mpptCount', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByNominalPowerKw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalPowerKw', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByNominalPowerKwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalPowerKw', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByNominalVoltageAc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageAc', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByNominalVoltageAcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageAc', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByNominalVoltageDc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageDc', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByNominalVoltageDcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageDc', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByProtectionDegree() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protectionDegree', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByProtectionDegreeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protectionDegree', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByStartVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByStartVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByWarrantyYears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyYears', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByWarrantyYearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyYears', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension InverterQuerySortThenBy
    on QueryBuilder<Inverter, Inverter, QSortThenBy> {
  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByDimensions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dimensions', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByDimensionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dimensions', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByEuroEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'euroEfficiency', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByEuroEfficiencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'euroEfficiency', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByGridConnection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridConnection', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByGridConnectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridConnection', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByInverterType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inverterType', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByInverterTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inverterType', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByIsHybrid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHybrid', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByIsHybridDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHybrid', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByManufacturer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByManufacturerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxEfficiency', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxEfficiencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxEfficiency', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      thenByMaxInputCurrentPerMppt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputCurrentPerMppt', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      thenByMaxInputCurrentPerMpptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputCurrentPerMppt', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxInputPowerKw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputPowerKw', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxInputPowerKwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputPowerKw', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxInputVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxInputVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxInputVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxMpptVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxMpptVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxMpptVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxMpptVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxOutputCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOutputCurrent', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMaxOutputCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOutputCurrent', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      thenByMaxShortCircuitCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxShortCircuitCurrent', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy>
      thenByMaxShortCircuitCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxShortCircuitCurrent', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMinMpptVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minMpptVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMinMpptVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minMpptVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMinOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMinOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMpptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mpptCount', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByMpptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mpptCount', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByNominalPowerKw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalPowerKw', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByNominalPowerKwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalPowerKw', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByNominalVoltageAc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageAc', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByNominalVoltageAcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageAc', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByNominalVoltageDc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageDc', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByNominalVoltageDcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nominalVoltageDc', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByProtectionDegree() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protectionDegree', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByProtectionDegreeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protectionDegree', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByStartVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVoltage', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByStartVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVoltage', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByWarrantyYears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyYears', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByWarrantyYearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyYears', Sort.desc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<Inverter, Inverter, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension InverterQueryWhereDistinct
    on QueryBuilder<Inverter, Inverter, QDistinct> {
  QueryBuilder<Inverter, Inverter, QDistinct> distinctByDimensions(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dimensions', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByEuroEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'euroEfficiency');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByGridConnection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gridConnection');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByInverterType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inverterType');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByIsHybrid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHybrid');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByManufacturer(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manufacturer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMaxEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxEfficiency');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct>
      distinctByMaxInputCurrentPerMppt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxInputCurrentPerMppt');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMaxInputPowerKw() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxInputPowerKw');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMaxInputVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxInputVoltage');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMaxMpptVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxMpptVoltage');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMaxOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxOperatingTemp');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMaxOutputCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxOutputCurrent');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct>
      distinctByMaxShortCircuitCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxShortCircuitCurrent');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMinMpptVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minMpptVoltage');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMinOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minOperatingTemp');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByModelName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByMpptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mpptCount');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByNominalPowerKw() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nominalPowerKw');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByNominalVoltageAc() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nominalVoltageAc');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByNominalVoltageDc() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nominalVoltageDc');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByProtectionDegree(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protectionDegree',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByStartVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startVoltage');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByWarrantyYears() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warrantyYears');
    });
  }

  QueryBuilder<Inverter, Inverter, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension InverterQueryProperty
    on QueryBuilder<Inverter, Inverter, QQueryProperty> {
  QueryBuilder<Inverter, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Inverter, String, QQueryOperations> dimensionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dimensions');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> euroEfficiencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'euroEfficiency');
    });
  }

  QueryBuilder<Inverter, GridConnection, QQueryOperations>
      gridConnectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gridConnection');
    });
  }

  QueryBuilder<Inverter, InverterType, QQueryOperations>
      inverterTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inverterType');
    });
  }

  QueryBuilder<Inverter, bool, QQueryOperations> isHybridProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHybrid');
    });
  }

  QueryBuilder<Inverter, String, QQueryOperations> manufacturerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manufacturer');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> maxEfficiencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxEfficiency');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations>
      maxInputCurrentPerMpptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxInputCurrentPerMppt');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> maxInputPowerKwProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxInputPowerKw');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> maxInputVoltageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxInputVoltage');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> maxMpptVoltageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxMpptVoltage');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> maxOperatingTempProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxOperatingTemp');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> maxOutputCurrentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxOutputCurrent');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations>
      maxShortCircuitCurrentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxShortCircuitCurrent');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> minMpptVoltageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minMpptVoltage');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> minOperatingTempProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minOperatingTemp');
    });
  }

  QueryBuilder<Inverter, String, QQueryOperations> modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<Inverter, int, QQueryOperations> mpptCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mpptCount');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> nominalPowerKwProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nominalPowerKw');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> nominalVoltageAcProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nominalVoltageAc');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> nominalVoltageDcProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nominalVoltageDc');
    });
  }

  QueryBuilder<Inverter, String, QQueryOperations> protectionDegreeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protectionDegree');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> startVoltageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startVoltage');
    });
  }

  QueryBuilder<Inverter, int, QQueryOperations> warrantyYearsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warrantyYears');
    });
  }

  QueryBuilder<Inverter, double, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
