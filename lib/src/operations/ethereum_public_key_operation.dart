import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart/crypto.dart';

import '../model/account.dart';
import '../utils/utils.dart';

class EthereumPublicKeyOperation extends LedgerOperation<Account> {
  final int accountIndex;

  EthereumPublicKeyOperation({
    this.accountIndex = 0,
  });

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0);
    writer.writeUint8(0x02);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    final List<int> paths = splitPath("44'/60'/0'/0/$accountIndex");
    final int bufferSize = 1 + paths.length * 4;
    final ByteData buffer = ByteData(bufferSize)..setUint8(0, paths.length);
    for (int i = 0; i < paths.length; i++) {
      buffer.setUint32(1 + 4 * i, paths[i], Endian.big);
    }

    final List<int> bufferBytes = buffer.buffer.asUint8List();
    writer.writeUint8(buffer.lengthInBytes);
    writer.write(bufferBytes);

    return [writer.toBytes()];
  }

  @override
  Future<Account> read(ByteDataReader reader) async {
    final bytes = reader.read(reader.remainingLength);
    int publicKeyLength = bytes[0];
    int addressLength = bytes[1 + publicKeyLength];
    final publicKey =
        bytesToHex(bytes.sublist(1, 1 + publicKeyLength), include0x: true);
    final address =
        '0x${utf8.decode(bytes.sublist(1 + publicKeyLength + 1, 1 + publicKeyLength + 1 + addressLength))}';
    return Account(publicKey: publicKey, address: address);
  }
}
