import 'dart:convert';
import 'dart:typed_data';

import 'package:web3dart_avacus/crypto.dart';

import 'length_tracking_byte_sink.dart';
import 'utils.dart';

void _encodeString(Uint8List string, LengthTrackingByteSink builder) {
  // For a single byte in [0x00, 0x7f], that byte is its own RLP encoding
  if (string.length == 1 && string[0] <= 0x7f) {
    builder.addByte(string[0]);
    return;
  }

  // If a string is between 0 and 55 bytes long, its encoding is 0x80 plus
  // its length, followed by the actual string
  if (string.length <= 55) {
    builder
      ..addByte(0x80 + string.length)
      ..add(string);
    return;
  }

  // More than 55 bytes long, RLP is (0xb7 + length of encoded length), followed
  // by the length, followed by the actual string
  final length = string.length;
  final encodedLength = unsignedIntToBytes(BigInt.from(length));

  builder
    ..addByte(0xb7 + encodedLength.length)
    ..add(encodedLength)
    ..add(string);
}

void encodeList(List list, LengthTrackingByteSink builder) {
  final subBuilder = LengthTrackingByteSink();
  for (final item in list) {
    _encodeToBuffer(item, subBuilder);
  }

  final length = subBuilder.length;
  if (length <= 55) {
    builder
      ..addByte(0xc0 + length)
      ..add(subBuilder.asBytes());
    return;
  } else {
    final encodedLength = unsignedIntToBytes(BigInt.from(length));

    builder
      ..addByte(0xf7 + encodedLength.length)
      ..add(encodedLength)
      ..add(subBuilder.asBytes());
    return;
  }
}

void _encodeInt(BigInt val, LengthTrackingByteSink builder) {
  if (val == BigInt.zero) {
    _encodeString(Uint8List(0), builder);
  } else {
    _encodeString(unsignedIntToBytes(val), builder);
  }
}

void _encodeToBuffer(dynamic value, LengthTrackingByteSink builder) {
  if (value is Uint8List) {
    _encodeString(value, builder);
  } else if (value is List) {
    encodeList(value, builder);
  } else if (value is BigInt) {
    _encodeInt(value, builder);
  } else if (value is int) {
    _encodeInt(BigInt.from(value), builder);
  } else if (value is String) {
    _encodeString(uint8ListFromList(utf8.encode(value)), builder);
  } else {
    throw UnsupportedError('$value cannot be rlp-encoded');
  }
}

Uint8List encode(dynamic value) {
  final builder = LengthTrackingByteSink();
  _encodeToBuffer(value, builder);

  return builder.asBytes();
}

int unarrayifyInteger(Uint8List data, int offset, int length) {
  var result = 0;
  for (var i = 0; i < length; i++) {
    result = (result * 256) + data[offset + i];
  }
  return result;
}

class Decoded {
  dynamic result;
  int consumed;

  Decoded(this.result, this.consumed);
}

Decoded _decodeChildren(
    Uint8List data, int offset, int childOffset, int length) {
  final result = [];

  while (childOffset < offset + 1 + length) {
    final decoded = _decode(data, childOffset);
    result.add(decoded.result);

    childOffset += decoded.consumed;
    if (childOffset > offset + 1 + length) {
      throw ArgumentError("child data too short");
    }
  }

  return Decoded(result, 1 + length);
}

Decoded _decode(Uint8List data, int offset) {
  if (data.isEmpty) {
    throw ArgumentError("data too short");
  }

  if (data[offset] >= 0xf8) {
    final lengthLength = data[offset] - 0xf7;
    if (offset + 1 + lengthLength > data.length) {
      throw ArgumentError("data short segment too short");
    }

    final length = unarrayifyInteger(data, offset + 1, lengthLength);
    if (offset + 1 + lengthLength + length > data.length) {
      throw ArgumentError("data long segment too short");
    }

    return _decodeChildren(
        data, offset, offset + 1 + lengthLength, lengthLength + length);
  } else if (data[offset] >= 0xc0) {
    final length = data[offset] - 0xc0;
    if (offset + 1 + length > data.length) {
      throw ArgumentError("data array too short");
    }

    return _decodeChildren(data, offset, offset + 1, length);
  } else if (data[offset] >= 0xb8) {
    final lengthLength = data[offset] - 0xb7;
    if (offset + 1 + lengthLength > data.length) {
      throw ArgumentError("data array too short");
    }

    final length = unarrayifyInteger(data, offset + 1, lengthLength);
    if (offset + 1 + lengthLength + length > data.length) {
      throw ArgumentError("data array too short");
    }

    final result = data.sublist(
        offset + 1 + lengthLength, offset + 1 + lengthLength + length);
    return Decoded(result, 1 + lengthLength + length);
  } else if (data[offset] >= 0x80) {
    final length = data[offset] - 0x80;
    if (offset + 1 + length > data.length) {
      throw ArgumentError("data too short");
    }

    final result = data.sublist(offset + 1, offset + 1 + length);
    return Decoded(result, 1 + length);
  }

  return Decoded([data[offset]], 1);
}

dynamic decode(Uint8List data) {
  final decoded = _decode(data, 0);
  if (decoded.consumed != data.length) {
    throw ArgumentError("invalid rlp data");
  }
  return decoded.result;
}
