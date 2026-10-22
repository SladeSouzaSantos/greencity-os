// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pv_module.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPvModuleCollection on Isar {
  IsarCollection<PvModule> get pvModules => this.collection();
}

const PvModuleSchema = CollectionSchema(
  name: r'PvModule',
  id: 1341550961362990066,
  properties: {
    r'cellTechnology': PropertySchema(
      id: 0,
      name: r'cellTechnology',
      type: IsarType.byte,
      enumMap: _PvModulecellTechnologyEnumValueMap,
    ),
    r'efficiency': PropertySchema(
      id: 1,
      name: r'efficiency',
      type: IsarType.double,
    ),
    r'efficiencyLoss': PropertySchema(
      id: 2,
      name: r'efficiencyLoss',
      type: IsarType.double,
    ),
    r'efficiencyWarranty': PropertySchema(
      id: 3,
      name: r'efficiencyWarranty',
      type: IsarType.long,
    ),
    r'fuseCurrent': PropertySchema(
      id: 4,
      name: r'fuseCurrent',
      type: IsarType.double,
    ),
    r'iMp': PropertySchema(
      id: 5,
      name: r'iMp',
      type: IsarType.double,
    ),
    r'iSc': PropertySchema(
      id: 6,
      name: r'iSc',
      type: IsarType.double,
    ),
    r'isBifacial': PropertySchema(
      id: 7,
      name: r'isBifacial',
      type: IsarType.bool,
    ),
    r'isTier1': PropertySchema(
      id: 8,
      name: r'isTier1',
      type: IsarType.bool,
    ),
    r'length': PropertySchema(
      id: 9,
      name: r'length',
      type: IsarType.double,
    ),
    r'manufacturer': PropertySchema(
      id: 10,
      name: r'manufacturer',
      type: IsarType.string,
    ),
    r'maxOperatingTemp': PropertySchema(
      id: 11,
      name: r'maxOperatingTemp',
      type: IsarType.double,
    ),
    r'maxSystemVoltage': PropertySchema(
      id: 12,
      name: r'maxSystemVoltage',
      type: IsarType.double,
    ),
    r'minOperatingTemp': PropertySchema(
      id: 13,
      name: r'minOperatingTemp',
      type: IsarType.double,
    ),
    r'modelName': PropertySchema(
      id: 14,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'physicalWarranty': PropertySchema(
      id: 15,
      name: r'physicalWarranty',
      type: IsarType.long,
    ),
    r'powerWp': PropertySchema(
      id: 16,
      name: r'powerWp',
      type: IsarType.long,
    ),
    r'tempCoefIsc': PropertySchema(
      id: 17,
      name: r'tempCoefIsc',
      type: IsarType.double,
    ),
    r'tempCoefPmax': PropertySchema(
      id: 18,
      name: r'tempCoefPmax',
      type: IsarType.double,
    ),
    r'tempCoefVoc': PropertySchema(
      id: 19,
      name: r'tempCoefVoc',
      type: IsarType.double,
    ),
    r'vMp': PropertySchema(
      id: 20,
      name: r'vMp',
      type: IsarType.double,
    ),
    r'vOc': PropertySchema(
      id: 21,
      name: r'vOc',
      type: IsarType.double,
    ),
    r'weight': PropertySchema(
      id: 22,
      name: r'weight',
      type: IsarType.double,
    ),
    r'width': PropertySchema(
      id: 23,
      name: r'width',
      type: IsarType.double,
    )
  },
  estimateSize: _pvModuleEstimateSize,
  serialize: _pvModuleSerialize,
  deserialize: _pvModuleDeserialize,
  deserializeProp: _pvModuleDeserializeProp,
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
  getId: _pvModuleGetId,
  getLinks: _pvModuleGetLinks,
  attach: _pvModuleAttach,
  version: '3.1.0+1',
);

int _pvModuleEstimateSize(
  PvModule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.manufacturer.length * 3;
  bytesCount += 3 + object.modelName.length * 3;
  return bytesCount;
}

void _pvModuleSerialize(
  PvModule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.cellTechnology.index);
  writer.writeDouble(offsets[1], object.efficiency);
  writer.writeDouble(offsets[2], object.efficiencyLoss);
  writer.writeLong(offsets[3], object.efficiencyWarranty);
  writer.writeDouble(offsets[4], object.fuseCurrent);
  writer.writeDouble(offsets[5], object.iMp);
  writer.writeDouble(offsets[6], object.iSc);
  writer.writeBool(offsets[7], object.isBifacial);
  writer.writeBool(offsets[8], object.isTier1);
  writer.writeDouble(offsets[9], object.length);
  writer.writeString(offsets[10], object.manufacturer);
  writer.writeDouble(offsets[11], object.maxOperatingTemp);
  writer.writeDouble(offsets[12], object.maxSystemVoltage);
  writer.writeDouble(offsets[13], object.minOperatingTemp);
  writer.writeString(offsets[14], object.modelName);
  writer.writeLong(offsets[15], object.physicalWarranty);
  writer.writeLong(offsets[16], object.powerWp);
  writer.writeDouble(offsets[17], object.tempCoefIsc);
  writer.writeDouble(offsets[18], object.tempCoefPmax);
  writer.writeDouble(offsets[19], object.tempCoefVoc);
  writer.writeDouble(offsets[20], object.vMp);
  writer.writeDouble(offsets[21], object.vOc);
  writer.writeDouble(offsets[22], object.weight);
  writer.writeDouble(offsets[23], object.width);
}

PvModule _pvModuleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PvModule(
    cellTechnology: _PvModulecellTechnologyValueEnumMap[
            reader.readByteOrNull(offsets[0])] ??
        CellTechnology.alBSF,
    efficiency: reader.readDouble(offsets[1]),
    efficiencyLoss: reader.readDoubleOrNull(offsets[2]) ?? 20,
    efficiencyWarranty: reader.readLongOrNull(offsets[3]) ?? 25,
    fuseCurrent: reader.readDoubleOrNull(offsets[4]) ?? 25,
    iMp: reader.readDouble(offsets[5]),
    iSc: reader.readDouble(offsets[6]),
    isBifacial: reader.readBool(offsets[7]),
    isTier1: reader.readBoolOrNull(offsets[8]) ?? true,
    length: reader.readDouble(offsets[9]),
    manufacturer: reader.readString(offsets[10]),
    maxOperatingTemp: reader.readDoubleOrNull(offsets[11]) ?? 85,
    maxSystemVoltage: reader.readDoubleOrNull(offsets[12]) ?? 1500,
    minOperatingTemp: reader.readDoubleOrNull(offsets[13]) ?? -40,
    modelName: reader.readString(offsets[14]),
    physicalWarranty: reader.readLongOrNull(offsets[15]) ?? 10,
    powerWp: reader.readLong(offsets[16]),
    tempCoefIsc: reader.readDouble(offsets[17]),
    tempCoefPmax: reader.readDouble(offsets[18]),
    tempCoefVoc: reader.readDouble(offsets[19]),
    vMp: reader.readDouble(offsets[20]),
    vOc: reader.readDouble(offsets[21]),
    weight: reader.readDouble(offsets[22]),
    width: reader.readDouble(offsets[23]),
  );
  object.id = id;
  return object;
}

P _pvModuleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_PvModulecellTechnologyValueEnumMap[
              reader.readByteOrNull(offset)] ??
          CellTechnology.alBSF) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset) ?? 20) as P;
    case 3:
      return (reader.readLongOrNull(offset) ?? 25) as P;
    case 4:
      return (reader.readDoubleOrNull(offset) ?? 25) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset) ?? 85) as P;
    case 12:
      return (reader.readDoubleOrNull(offset) ?? 1500) as P;
    case 13:
      return (reader.readDoubleOrNull(offset) ?? -40) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset) ?? 10) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    case 17:
      return (reader.readDouble(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readDouble(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readDouble(offset)) as P;
    case 22:
      return (reader.readDouble(offset)) as P;
    case 23:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PvModulecellTechnologyEnumValueMap = {
  'alBSF': 0,
  'perc': 1,
  'topcon': 2,
  'hjt': 3,
};
const _PvModulecellTechnologyValueEnumMap = {
  0: CellTechnology.alBSF,
  1: CellTechnology.perc,
  2: CellTechnology.topcon,
  3: CellTechnology.hjt,
};

Id _pvModuleGetId(PvModule object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pvModuleGetLinks(PvModule object) {
  return [];
}

void _pvModuleAttach(IsarCollection<dynamic> col, Id id, PvModule object) {
  object.id = id;
}

extension PvModuleQueryWhereSort on QueryBuilder<PvModule, PvModule, QWhere> {
  QueryBuilder<PvModule, PvModule, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PvModuleQueryWhere on QueryBuilder<PvModule, PvModule, QWhereClause> {
  QueryBuilder<PvModule, PvModule, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PvModule, PvModule, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterWhereClause> idBetween(
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

  QueryBuilder<PvModule, PvModule, QAfterWhereClause> manufacturerEqualTo(
      String manufacturer) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'manufacturer',
        value: [manufacturer],
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterWhereClause> manufacturerNotEqualTo(
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

extension PvModuleQueryFilter
    on QueryBuilder<PvModule, PvModule, QFilterCondition> {
  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> cellTechnologyEqualTo(
      CellTechnology value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cellTechnology',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      cellTechnologyGreaterThan(
    CellTechnology value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cellTechnology',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      cellTechnologyLessThan(
    CellTechnology value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cellTechnology',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> cellTechnologyBetween(
    CellTechnology lower,
    CellTechnology upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cellTechnology',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> efficiencyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'efficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> efficiencyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'efficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> efficiencyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'efficiency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> efficiencyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'efficiency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> efficiencyLossEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'efficiencyLoss',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      efficiencyLossGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'efficiencyLoss',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      efficiencyLossLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'efficiencyLoss',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> efficiencyLossBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'efficiencyLoss',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      efficiencyWarrantyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'efficiencyWarranty',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      efficiencyWarrantyGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'efficiencyWarranty',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      efficiencyWarrantyLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'efficiencyWarranty',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      efficiencyWarrantyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'efficiencyWarranty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> fuseCurrentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuseCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      fuseCurrentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fuseCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> fuseCurrentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fuseCurrent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> fuseCurrentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fuseCurrent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iMpEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iMp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iMpGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iMp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iMpLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iMp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iMpBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iMp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iScEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iSc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iScGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iSc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iScLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iSc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> iScBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iSc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> isBifacialEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isBifacial',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> isTier1EqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isTier1',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> lengthEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> lengthGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> lengthLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'length',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> lengthBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'length',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> manufacturerEqualTo(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> manufacturerLessThan(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> manufacturerBetween(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> manufacturerEndsWith(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> manufacturerContains(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> manufacturerMatches(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      manufacturerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manufacturer',
        value: '',
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      manufacturerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'manufacturer',
        value: '',
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      maxSystemVoltageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxSystemVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      maxSystemVoltageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxSystemVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      maxSystemVoltageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxSystemVoltage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      maxSystemVoltageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxSystemVoltage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameEqualTo(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameGreaterThan(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameLessThan(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameBetween(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameStartsWith(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameEndsWith(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameContains(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameMatches(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      physicalWarrantyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'physicalWarranty',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      physicalWarrantyGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'physicalWarranty',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      physicalWarrantyLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'physicalWarranty',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      physicalWarrantyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'physicalWarranty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> powerWpEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'powerWp',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> powerWpGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'powerWp',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> powerWpLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'powerWp',
        value: value,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> powerWpBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'powerWp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefIscEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempCoefIsc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      tempCoefIscGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tempCoefIsc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefIscLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tempCoefIsc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefIscBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tempCoefIsc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefPmaxEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempCoefPmax',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      tempCoefPmaxGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tempCoefPmax',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefPmaxLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tempCoefPmax',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefPmaxBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tempCoefPmax',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefVocEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempCoefVoc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition>
      tempCoefVocGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tempCoefVoc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefVocLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tempCoefVoc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> tempCoefVocBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tempCoefVoc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vMpEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vMp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vMpGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vMp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vMpLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vMp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vMpBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vMp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vOcEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vOc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vOcGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vOc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vOcLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vOc',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> vOcBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vOc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> weightEqualTo(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> weightGreaterThan(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> weightLessThan(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> weightBetween(
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

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> widthEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> widthGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> widthLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'width',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterFilterCondition> widthBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'width',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension PvModuleQueryObject
    on QueryBuilder<PvModule, PvModule, QFilterCondition> {}

extension PvModuleQueryLinks
    on QueryBuilder<PvModule, PvModule, QFilterCondition> {}

extension PvModuleQuerySortBy on QueryBuilder<PvModule, PvModule, QSortBy> {
  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByCellTechnology() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellTechnology', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByCellTechnologyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellTechnology', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiency', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByEfficiencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiency', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByEfficiencyLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyLoss', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByEfficiencyLossDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyLoss', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByEfficiencyWarranty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyWarranty', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy>
      sortByEfficiencyWarrantyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyWarranty', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByFuseCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuseCurrent', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByFuseCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuseCurrent', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByIMp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iMp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByIMpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iMp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByISc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iSc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByIScDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iSc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByIsBifacial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBifacial', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByIsBifacialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBifacial', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByIsTier1() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTier1', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByIsTier1Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTier1', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByManufacturer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByManufacturerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByMaxOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByMaxOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByMaxSystemVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSystemVoltage', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByMaxSystemVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSystemVoltage', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByMinOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByMinOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByPhysicalWarranty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalWarranty', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByPhysicalWarrantyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalWarranty', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByPowerWp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'powerWp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByPowerWpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'powerWp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByTempCoefIsc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefIsc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByTempCoefIscDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefIsc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByTempCoefPmax() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefPmax', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByTempCoefPmaxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefPmax', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByTempCoefVoc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefVoc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByTempCoefVocDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefVoc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByVMp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vMp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByVMpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vMp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByVOc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByVOcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> sortByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension PvModuleQuerySortThenBy
    on QueryBuilder<PvModule, PvModule, QSortThenBy> {
  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByCellTechnology() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellTechnology', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByCellTechnologyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellTechnology', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiency', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByEfficiencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiency', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByEfficiencyLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyLoss', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByEfficiencyLossDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyLoss', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByEfficiencyWarranty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyWarranty', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy>
      thenByEfficiencyWarrantyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'efficiencyWarranty', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByFuseCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuseCurrent', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByFuseCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuseCurrent', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIMp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iMp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIMpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iMp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByISc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iSc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIScDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iSc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIsBifacial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBifacial', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIsBifacialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBifacial', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIsTier1() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTier1', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByIsTier1Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTier1', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'length', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByManufacturer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByManufacturerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manufacturer', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByMaxOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByMaxOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByMaxSystemVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSystemVoltage', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByMaxSystemVoltageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSystemVoltage', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByMinOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByMinOperatingTempDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOperatingTemp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByPhysicalWarranty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalWarranty', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByPhysicalWarrantyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalWarranty', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByPowerWp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'powerWp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByPowerWpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'powerWp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByTempCoefIsc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefIsc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByTempCoefIscDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefIsc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByTempCoefPmax() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefPmax', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByTempCoefPmaxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefPmax', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByTempCoefVoc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefVoc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByTempCoefVocDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempCoefVoc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByVMp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vMp', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByVMpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vMp', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByVOc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOc', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByVOcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOc', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<PvModule, PvModule, QAfterSortBy> thenByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension PvModuleQueryWhereDistinct
    on QueryBuilder<PvModule, PvModule, QDistinct> {
  QueryBuilder<PvModule, PvModule, QDistinct> distinctByCellTechnology() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cellTechnology');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByEfficiency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'efficiency');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByEfficiencyLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'efficiencyLoss');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByEfficiencyWarranty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'efficiencyWarranty');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByFuseCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fuseCurrent');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByIMp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iMp');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByISc() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iSc');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByIsBifacial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBifacial');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByIsTier1() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTier1');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'length');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByManufacturer(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manufacturer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByMaxOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxOperatingTemp');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByMaxSystemVoltage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxSystemVoltage');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByMinOperatingTemp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minOperatingTemp');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByModelName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByPhysicalWarranty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'physicalWarranty');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByPowerWp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'powerWp');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByTempCoefIsc() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tempCoefIsc');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByTempCoefPmax() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tempCoefPmax');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByTempCoefVoc() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tempCoefVoc');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByVMp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vMp');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByVOc() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vOc');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }

  QueryBuilder<PvModule, PvModule, QDistinct> distinctByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'width');
    });
  }
}

extension PvModuleQueryProperty
    on QueryBuilder<PvModule, PvModule, QQueryProperty> {
  QueryBuilder<PvModule, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PvModule, CellTechnology, QQueryOperations>
      cellTechnologyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cellTechnology');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> efficiencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'efficiency');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> efficiencyLossProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'efficiencyLoss');
    });
  }

  QueryBuilder<PvModule, int, QQueryOperations> efficiencyWarrantyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'efficiencyWarranty');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> fuseCurrentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fuseCurrent');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> iMpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iMp');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> iScProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iSc');
    });
  }

  QueryBuilder<PvModule, bool, QQueryOperations> isBifacialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBifacial');
    });
  }

  QueryBuilder<PvModule, bool, QQueryOperations> isTier1Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTier1');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> lengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'length');
    });
  }

  QueryBuilder<PvModule, String, QQueryOperations> manufacturerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manufacturer');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> maxOperatingTempProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxOperatingTemp');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> maxSystemVoltageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxSystemVoltage');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> minOperatingTempProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minOperatingTemp');
    });
  }

  QueryBuilder<PvModule, String, QQueryOperations> modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<PvModule, int, QQueryOperations> physicalWarrantyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'physicalWarranty');
    });
  }

  QueryBuilder<PvModule, int, QQueryOperations> powerWpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'powerWp');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> tempCoefIscProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tempCoefIsc');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> tempCoefPmaxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tempCoefPmax');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> tempCoefVocProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tempCoefVoc');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> vMpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vMp');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> vOcProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vOc');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }

  QueryBuilder<PvModule, double, QQueryOperations> widthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'width');
    });
  }
}
