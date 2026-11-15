import 'dart:convert';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import 'key_value_text.dart';

List<List<int>> parseRedisCommand(String input) {
  final bytes = utf8.encode(input);
  final args = <List<int>>[];
  var offset = 0;
  bool whitespace(int byte) => byte == 32 || (byte >= 9 && byte <= 13);
  int? hex(int byte) => int.tryParse(String.fromCharCode(byte), radix: 16);

  while (offset < bytes.length) {
    if (whitespace(bytes[offset])) {
      offset++;
      continue;
    }
    final arg = <int>[];
    int? quote;
    while (offset < bytes.length) {
      final byte = bytes[offset++];
      if (quote == null && whitespace(byte)) break;
      if (quote != null && byte == quote) {
        if (offset < bytes.length && !whitespace(bytes[offset])) {
          throw const FormatException(
            'Expected whitespace after closing quote.',
          );
        }
        quote = null;
        break;
      }
      if (quote == null && (byte == 34 || byte == 39)) {
        if (arg.isNotEmpty) {
          throw const FormatException(
            'Expected whitespace before opening quote.',
          );
        }
        quote = byte;
      } else if (byte == 92 && offset < bytes.length && quote == 34) {
        final escaped = bytes[offset++];
        if (escaped == 120 && offset + 1 < bytes.length) {
          final high = hex(bytes[offset]);
          final low = hex(bytes[offset + 1]);
          if (high != null && low != null) {
            arg.add(high * 16 + low);
            offset += 2;
            continue;
          }
        }
        arg.add(switch (escaped) {
          110 => 10,
          114 => 13,
          116 => 9,
          98 => 8,
          97 => 7,
          _ => escaped,
        });
      } else if (byte == 92 &&
          quote == 39 &&
          offset < bytes.length &&
          bytes[offset] == 39) {
        arg.add(bytes[offset++]);
      } else {
        arg.add(byte);
      }
    }
    if (quote != null) throw const FormatException('Unclosed quote.');
    args.add(arg);
  }
  return args;
}

String quoteRedisArgument(List<int> bytes) {
  final text = utf8Text(bytes);
  if (text != null &&
      text.isNotEmpty &&
      !RegExp(r'''[\s"'\\]''').hasMatch(text) &&
      !text.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    return text;
  }
  return '"${bytes.map((byte) => '\\x${byte.toRadixString(16).padLeft(2, '0')}').join()}"';
}

const redisCommands = [
  'APPEND',
  'DBSIZE',
  'DEL',
  'EXISTS',
  'EXPIRE',
  'GET',
  'GETRANGE',
  'HDEL',
  'HGET',
  'HSCAN',
  'HSET',
  'INFO',
  'JSON.GET',
  'JSON.SET',
  'LLEN',
  'LRANGE',
  'LSET',
  'MGET',
  'PERSIST',
  'PFCOUNT',
  'PING',
  'PTTL',
  'PUBLISH',
  'RENAME',
  'RPUSH',
  'SADD',
  'SCAN',
  'SET',
  'SREM',
  'SSCAN',
  'TTL',
  'TYPE',
  'XADD',
  'XDEL',
  'XRANGE',
  'ZADD',
  'ZRANGE',
  'ZREM',
  'ZSCAN',
];

String formatRedisReply(RespValue value) => switch (value.whichKind()) {
  RespValue_Kind.stringValue => '(string) ${displayBytes(value.stringValue)}',
  RespValue_Kind.integer => '(integer) ${value.integer}',
  RespValue_Kind.doubleValue => '(double) ${value.doubleValue}',
  RespValue_Kind.boolean => '(boolean) ${value.boolean}',
  RespValue_Kind.nil => '(nil)',
  RespValue_Kind.array => _items('array', value.array.items),
  RespValue_Kind.set => _items('set', value.set.items),
  RespValue_Kind.map =>
    '(map) {\n${_indent(value.map.entries.map((entry) => '${formatRedisReply(entry.key)}: ${formatRedisReply(entry.value)}').join('\n'))}\n}',
  RespValue_Kind.verbatim =>
    '(${value.verbatim.format}) ${value.verbatim.text}',
  RespValue_Kind.error => '(error) ${value.error}',
  RespValue_Kind.notSet => '(empty reply)',
};

String _items(String type, List<RespValue> items) =>
    '($type) [\n${_indent(items.map(formatRedisReply).join('\n'))}\n]';

String _indent(String text) =>
    text.split('\n').map((line) => '  $line').join('\n');
