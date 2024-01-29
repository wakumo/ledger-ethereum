import 'dart:typed_data';

class DecodedTransaction {
  Uint8List data;
  Uint8List to;
  BigInt chainId;

  DecodedTransaction(
      {required this.data, required this.to, required this.chainId});
}
