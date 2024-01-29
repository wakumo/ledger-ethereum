import 'decoded_transaction.dart';

class DecodedInfo {
  DecodedTransaction decodedTx;
  int? txType;
  BigInt chainId;
  int chainIdTruncated;
  int vrsOffset;

  DecodedInfo({
    required this.decodedTx,
    this.txType,
    required this.chainId,
    required this.chainIdTruncated,
    required this.vrsOffset,
  });
}
