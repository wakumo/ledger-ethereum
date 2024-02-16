import 'dart:typed_data';

import 'package:ledger_flutter/ledger_flutter.dart';

import '../model/signature.dart';
import '../utils/utils.dart';

class EthereumEIP712HashedMessageOperation extends LedgerOperation<Signature> {
  final int accountIndex;
  final Uint8List domainSeparator;
  final Uint8List hashStructMessage;

  EthereumEIP712HashedMessageOperation(
      {this.accountIndex = 0,
      required this.domainSeparator,
      required this.hashStructMessage});

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0);
    writer.writeUint8(0x0c);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));
    final buffer = Uint8List(1 + paths.length * 4 + 32 + 32);
    var offset = 0;
    buffer[0] = paths.length;
    for (var index = 0; index < paths.length; index++) {
      buffer.buffer
          .asByteData()
          .setUint32(1 + 4 * index, paths[index], Endian.big);
    }
    offset = 1 + 4 * paths.length;
    buffer.setAll(offset, domainSeparator);
    offset += 32;
    buffer.setAll(offset, hashStructMessage);

    final List<int> bufferBytes = buffer.buffer.asUint8List();
    writer.writeUint8(buffer.lengthInBytes);
    writer.write(bufferBytes);

    return [writer.toBytes()];
  }

  @override
  Future<Signature> read(ByteDataReader reader) async {
    final bytes = reader.read(reader.remainingLength);
    int v = bytes[0];
    String r = bytes
        .sublist(1, 1 + 32)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
    String s = bytes
        .sublist(1 + 32, 1 + 32 + 32)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
    return Signature(v: v, r: r, s: s);
  }
}
