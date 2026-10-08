import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';

/// Tesco en Londres: la cotización principal de su ISIN.
const tescoLondon = SymbolMatch(
  symbol: 'LSE:TSCO',
  name: 'Tesco PLC',
  region: 'GB',
  currency: 'GBX',
  matchScore: 1,
  isin: 'GB0008847096',
  exchange: 'LSE',
  exchangeName: 'London Stock Exchange',
  isPrimaryListing: true,
);

/// Tesco en Fráncfort, en euros: la misma empresa, otra cotización.
const tescoFrankfurt = SymbolMatch(
  symbol: 'GETTEX:TCO',
  name: 'Tesco PLC',
  region: 'DE',
  currency: 'EUR',
  matchScore: 0.9,
  isin: 'GB0008847096',
  exchange: 'GETTEX',
  exchangeName: 'Gettex',
);

/// Un certificado ADR con su propio ISIN.
const tescoReceipt = SymbolMatch(
  symbol: 'OTC:TSCDY',
  name: 'Tesco PLC ADR',
  region: 'US',
  currency: 'USD',
  matchScore: 0.5,
  isin: 'US8815751099',
  exchange: 'OTC',
  exchangeName: 'OTC Markets',
  isDepositaryReceipt: true,
);
