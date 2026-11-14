import 'dart:convert';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';

String keyIdentity(List<int> key) => base64Encode(key);
List<int> keyBytes(String identity) => base64Decode(identity);

String hexBytes(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');

String? utf8Text(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return null;
  }
}

String displayBytes(List<int> bytes) {
  final text = utf8Text(bytes);
  if (text != null && !text.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    return text.isEmpty ? '""' : text;
  }
  return '0x${hexBytes(bytes)}';
}

String keyTypeLabel(KeyType type) => switch (type) {
  KeyType.KEY_TYPE_STRING => 'string',
  KeyType.KEY_TYPE_HASH => 'hash',
  KeyType.KEY_TYPE_LIST => 'list',
  KeyType.KEY_TYPE_SET => 'set',
  KeyType.KEY_TYPE_ZSET => 'zset',
  KeyType.KEY_TYPE_STREAM => 'stream',
  KeyType.KEY_TYPE_JSON => 'JSON',
  KeyType.KEY_TYPE_HYPERLOGLOG => 'HyperLogLog',
  _ => 'unknown',
};

String ttlLabel(int milliseconds) => switch (milliseconds) {
  -1 => 'Persistent',
  < 0 => 'TTL unknown',
  _ => '$milliseconds ms',
};

List<int> parseHex(String text) {
  final digits = text.replaceAll(RegExp(r'\s+'), '');
  if (digits.length.isOdd || !RegExp(r'^[\da-fA-F]*$').hasMatch(digits)) {
    throw const FormatException('Enter pairs of hexadecimal digits.');
  }
  return [
    for (var offset = 0; offset < digits.length; offset += 2)
      int.parse(digits.substring(offset, offset + 2), radix: 16),
  ];
}
