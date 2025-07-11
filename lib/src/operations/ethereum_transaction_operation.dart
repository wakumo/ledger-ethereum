import 'dart:typed_data';

import 'package:ledger_ethereum/src/utils/transaction_handler.dart';
import 'package:ledger/ledger.dart';

import '../model/decoded_info.dart';
import '../utils/utils.dart';

class EthereumTransactionOperation
    extends LedgerOperation<Map<String, String>> {
  final int accountIndex;
  final Uint8List transaction;
  late DecodedInfo decodedInfo;

  EthereumTransactionOperation(
      {this.accountIndex = 0, required this.transaction});

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    decodedInfo = TransactionHandler.decodeTx(transaction);
    final vrsOffset = decodedInfo.vrsOffset;

    final output = <Uint8List>[];
    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));
    int offset = 0;
    while (offset != transaction.length) {
      final writer = ByteDataWriter();
      writer.writeUint8(0xe0);
      writer.writeUint8(0x04);

      bool first = offset == 0;
      int maxChunkSize = first ? 150 - 1 - paths.length * 4 : 150;
      int chunkSize = offset + maxChunkSize > transaction.length
          ? transaction.length - offset
          : maxChunkSize;

      if (vrsOffset != 0 && offset + chunkSize >= vrsOffset) {
        // Make sure that the chunk doesn't end right on the EIP 155 marker if set
        chunkSize = transaction.length - offset;
      }

      ByteData buffer =
          ByteData(first ? 1 + paths.length * 4 + chunkSize : chunkSize);

      if (first) {
        buffer.setUint8(0, paths.length);
        for (int i = 0; i < paths.length; i++) {
          buffer.setUint32(1 + 4 * i, paths[i], Endian.big);
        }
        buffer.buffer.asUint8List().setAll(1 + 4 * paths.length,
            transaction.sublist(offset, offset + chunkSize));
        writer.writeUint8(0x00);
      } else {
        buffer.buffer
            .asUint8List()
            .setAll(0, transaction.sublist(offset, offset + chunkSize));
        writer.writeUint8(0x80);
      }

      writer.writeUint8(0x00);

      final List<int> bufferBytes = buffer.buffer.asUint8List();
      writer.writeUint8(buffer.lengthInBytes);
      writer.write(bufferBytes);

      offset += chunkSize;

      output.add(writer.toBytes());
    }

    return output;
  }

  @override
  Future<Map<String, String>> read(ByteDataReader reader) async {
    final chainId = decodedInfo.chainId;
    final chainIdTruncated = decodedInfo.chainIdTruncated;
    final txType = decodedInfo.txType;

    final bytes = reader.read(reader.remainingLength);
    int responseByte = bytes[0];
    String v = "";

    if (chainId * BigInt.two + BigInt.from(35) + BigInt.one >
        BigInt.from(255)) {
      int oneByteChainId = (chainIdTruncated * 2 + 35) % 256;

      final eccParity = BigInt.from((responseByte - oneByteChainId).abs());

      if (txType != null) {
        // For EIP2930 and EIP1559 tx, v is simply the parity.
        v = eccParity.isOdd ? "00" : "01";
      } else {
        // Legacy type transaction with a big chain ID
        v = (chainId * BigInt.two + BigInt.from(35) + eccParity)
            .toRadixString(16);
      }
    } else {
      v = responseByte.toRadixString(16);
    }

    // Make sure v has is prefixed with a 0 if its length is odd ("1" -> "01").
    if (v.length % 2 == 1) {
      v = "0$v";
    }

    String r = bytes
        .sublist(1, 1 + 32)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
    String s = bytes
        .sublist(1 + 32, 1 + 32 + 32)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();

    return {'v': v, 'r': r, 's': s};
  }
}
