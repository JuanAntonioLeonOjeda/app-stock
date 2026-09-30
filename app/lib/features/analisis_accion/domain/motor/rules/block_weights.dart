import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';

/// Peso de cada bloque en la nota global, por horizonte (suman 1).
const blockWeights = <Horizon, Map<Block, double>>{
  Horizon.longTerm: {
    Block.valuation: 0.3,
    Block.health: 0.2,
    Block.growth: 0.3,
    Block.technical: 0.1,
    Block.context: 0.1,
  },
  Horizon.shortTerm: {
    Block.valuation: 0.2,
    Block.health: 0.15,
    Block.growth: 0.2,
    Block.technical: 0.35,
    Block.context: 0.1,
  },
};
