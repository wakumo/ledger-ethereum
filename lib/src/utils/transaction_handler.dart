import 'dart:typed_data';

import 'package:ledger_ethereum/src/model/decoded_transaction.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart_avacus/crypto.dart';
import 'package:web3dart_avacus/web3dart_avacus.dart';

import '../model/decoded_info.dart';
import 'rlp.dart';

class TransactionHandler {
  static const validTypes = [1, 2];

  static DecodedInfo decodeTx(Uint8List rawTx) {
    final type = int.parse(rawTx[0].toString());
    final txType = validTypes.contains(type) ? type : null;
    final rlpData = (txType == null) ? rawTx : rawTx.sublist(1);
    final rlpTx = decode(rlpData);

    int chainIdTruncated = 0;
    final rlpDecoded = decode(rlpData);

    Map<String, dynamic> decodedTx;
    if (txType == 2) {
      // EIP1559
      decodedTx = {
        'data': rlpDecoded[7],
        'to': rlpDecoded[5],
        'chainId': rlpTx[0],
      };
    } else if (txType == 1) {
      // EIP2930
      decodedTx = {
        'data': rlpDecoded[6],
        'to': rlpDecoded[4],
        'chainId': rlpTx[0],
      };
    } else {
      // Legacy tx
      decodedTx = {
        'data': rlpDecoded[5],
        'to': rlpDecoded[3],
        // Default to 1 for non EIP 155 txs
        'chainId': (rlpTx.length > 6) ? rlpTx[6] : Uint8List.fromList([0x01]),
      };
    }

    final chainIdSrc = decodedTx['chainId'];
    var chainId = BigInt.from(0);

    if (chainIdSrc != null) {
      // Using BigInt because chainID could be any uint256.
      chainId = BigInt.parse(
          chainIdSrc
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(),
          radix: 16);

      final chainIdTruncatedBuf = Uint8List(4);
      if (chainIdSrc.length > 4) {
        chainIdTruncatedBuf.setAll(0, chainIdSrc);
      } else {
        chainIdTruncatedBuf.setAll(
            (4 - (chainIdSrc.length as int)), chainIdSrc);
      }
      chainIdTruncated =
          ByteData.sublistView(Uint8List.fromList(chainIdTruncatedBuf))
              .getUint32(0, Endian.big);
    }

    int vrsOffset = 0;
    if (txType == null && rlpTx.length > 6) {
      final rlpVrs = Uint8List.fromList(
          encode(rlpTx.sublist(rlpTx.length - 3)).sublist(2));

      vrsOffset = rawTx.length - (rlpVrs.length - 1);

      // First byte > 0xf7 means the length of the list length doesn't fit in a single byte.
      if (rlpVrs[0] > 0xf7) {
        // Increment vrsOffset to account for that extra byte.
        vrsOffset++;

        // Compute size of the list length.
        final sizeOfListLen = rlpVrs[0] - 0xf7;

        // Increase vrsOffset by the size of the list length.
        vrsOffset += sizeOfListLen - 1;
      }
    }

    return DecodedInfo(
        decodedTx: DecodedTransaction(
            data: decodedTx['data'],
            to: decodedTx['to'],
            chainId: BigInt.parse(bytesToHex(decodedTx['chainId']))),
        txType: txType,
        chainId: chainId,
        chainIdTruncated: chainIdTruncated,
        vrsOffset: vrsOffset);
  }

  static Uint8List encodeTx(Transaction transaction, BigInt chainId,
      [MsgSignature? signature]) {
    if (transaction.isEIP1559) {
      final encodedTx = ByteDataWriter();
      encodedTx.writeUint8(0x02);
      encodedTx
          .write(encode(_encodeEIP1559ToRlp(transaction, chainId, signature)));
      return encodedTx.toBytes();
    }
    return encode(_encodeToRlp(transaction, chainId,
        signature ?? MsgSignature(BigInt.zero, BigInt.zero, chainId.toInt())));
  }

  static List<dynamic> _encodeEIP1559ToRlp(
      Transaction transaction, BigInt chainId, MsgSignature? signature) {
    final list = [
      chainId,
      transaction.nonce,
      transaction.maxPriorityFeePerGas!.getInWei,
      transaction.maxFeePerGas!.getInWei,
      transaction.maxGas,
    ];

    if (transaction.to != null) {
      list.add(transaction.to!.addressBytes);
    } else {
      list.add('');
    }

    list
      ..add(transaction.value?.getInWei)
      ..add(transaction.data);

    list.add([]); // access list

    if (signature != null) {
      list
        ..add(signature.v)
        ..add(signature.r)
        ..add(signature.s);
    }

    return list;
  }

  static List<dynamic> _encodeToRlp(
      Transaction transaction, BigInt chainId, MsgSignature? signature) {
    final list = [
      transaction.nonce,
      transaction.gasPrice?.getInWei,
      transaction.maxGas,
    ];

    if (transaction.to != null) {
      list.add(transaction.to!.addressBytes);
    } else {
      list.add('');
    }

    list
      ..add(transaction.value?.getInWei)
      ..add(transaction.data);

    if (signature != null) {
      list
        ..add(signature.v)
        ..add(signature.r)
        ..add(signature.s);
    }

    return list;
  }
}
