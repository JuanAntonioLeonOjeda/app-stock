import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';

const _longTermWeights = {
  Block.valuation: 0.3,
  Block.health: 0.2,
  Block.growth: 0.3,
  Block.technical: 0.1,
  Block.context: 0.1,
};

const _shortTermWeights = {
  Block.valuation: 0.2,
  Block.health: 0.15,
  Block.growth: 0.2,
  Block.technical: 0.35,
  Block.context: 0.1,
};

/// Peso de cada bloque en la nota global para [horizon] (suman 1).
Map<Block, double> blockWeightsFor(Horizon horizon) => switch (horizon) {
  Horizon.longTerm => _longTermWeights,
  Horizon.shortTerm => _shortTermWeights,
};
