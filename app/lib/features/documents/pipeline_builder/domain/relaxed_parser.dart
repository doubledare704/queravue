import 'dart:convert';

class RelaxedParseException extends FormatException {
  const RelaxedParseException(super.message, super.source, super.offset);
}

class RelaxedEjsonParser {
  RelaxedEjsonParser(this.source, {int start = 0}) : position = start;

  final String source;
  int position;

  Object? parseValue() {
    skipTrivia();
    final c = _peek();
    if (c == '{') return _object();
    if (c == '[') return _array();
    if (c == '"' || c == "'") return _string();
    if (c == '/') return _regex();
    if (c == '-' || _isDigit(c)) return _number();
    if (_isIdentStart(c)) return _word();
    throw _error('Unexpected ${c.isEmpty ? 'end of text' : "'$c'"}');
  }

  List<Object?> parseArrayElementsLeniently(
    void Function(String failedText) onFailed,
  ) {
    skipTrivia();
    _expect('[');
    final values = <Object?>[];
    while (true) {
      skipTrivia();
      if (_peek() == ']') {
        position++;
        return values;
      }
      if (_peek().isEmpty) throw _error('Unterminated array');
      final start = position;
      try {
        values.add(parseValue());
        skipTrivia();
        if (_peek() != ',' && _peek() != ']') throw _error('Expected , or ]');
      } on RelaxedParseException {
        position = start;
        _skipElement();
        values.add(_Failed(source.substring(start, position).trim()));
        onFailed(source.substring(start, position).trim());
      }
      skipTrivia();
      if (_peek() == ',') position++;
    }
  }

  void skipTrivia() {
    while (position < source.length) {
      final c = source[position];
      if (c == ' ' || c == '\n' || c == '\t' || c == '\r') {
        position++;
      } else if (source.startsWith('//', position)) {
        final end = source.indexOf('\n', position);
        position = end < 0 ? source.length : end + 1;
      } else if (source.startsWith('/*', position)) {
        final end = source.indexOf('*/', position + 2);
        if (end < 0) throw _error('Unterminated comment');
        position = end + 2;
      } else {
        return;
      }
    }
  }

  String _peek() => position < source.length ? source[position] : '';

  RelaxedParseException _error(String message) =>
      RelaxedParseException(message, source, position);

  void _expect(String c) {
    if (_peek() != c) throw _error("Expected '$c'");
    position++;
  }

  void _skipElement() {
    var depth = 0;
    while (position < source.length) {
      final c = source[position];
      if (c == '"' || c == "'") {
        _skipQuoted(c);
        continue;
      }
      if (c == '{' || c == '[' || c == '(') depth++;
      if (c == '}' || c == ')') depth--;
      if (c == ']') {
        if (depth == 0) return;
        depth--;
      }
      if (c == ',' && depth <= 0) return;
      position++;
    }
  }

  void _skipQuoted(String quote) {
    position++;
    while (position < source.length && source[position] != quote) {
      position += source[position] == r'\' ? 2 : 1;
    }
    position++;
  }

  Map<String, Object?> _object() {
    position++;
    final map = <String, Object?>{};
    while (true) {
      skipTrivia();
      if (_peek() == '}') {
        position++;
        return map;
      }
      final c = _peek();
      final key = (c == '"' || c == "'") ? _string() : _identifier();
      skipTrivia();
      _expect(':');
      map[key] = parseValue();
      skipTrivia();
      if (_peek() == ',') {
        position++;
      } else if (_peek() != '}') {
        throw _error('Expected , or }');
      }
    }
  }

  List<Object?> _array() {
    position++;
    final list = <Object?>[];
    while (true) {
      skipTrivia();
      if (_peek() == ']') {
        position++;
        return list;
      }
      list.add(parseValue());
      skipTrivia();
      if (_peek() == ',') {
        position++;
      } else if (_peek() != ']') {
        throw _error('Expected , or ]');
      }
    }
  }

  String _identifier() {
    final start = position;
    while (position < source.length && _isIdentPart(source[position])) {
      position++;
    }
    if (start == position) throw _error('Expected a key');
    return source.substring(start, position);
  }

  String _string() {
    final quote = source[position++];
    final b = StringBuffer();
    while (true) {
      if (position >= source.length) throw _error('Unterminated string');
      final c = source[position++];
      if (c == quote) return b.toString();
      if (c != r'\') {
        b.write(c);
        continue;
      }
      if (position >= source.length) throw _error('Unterminated string');
      final e = source[position++];
      switch (e) {
        case 'n':
          b.write('\n');
        case 't':
          b.write('\t');
        case 'r':
          b.write('\r');
        case 'b':
          b.write('\b');
        case 'f':
          b.write('\f');
        case 'u':
          final hex = source.substring(
            position,
            (position + 4).clamp(0, source.length),
          );
          final code = int.tryParse(hex, radix: 16);
          if (hex.length != 4 || code == null) throw _error('Bad \\u escape');
          b.writeCharCode(code);
          position += 4;
        default:
          b.write(e);
      }
    }
  }

  Object? _number() {
    final match = RegExp(r'-?\d+(\.\d+)?([eE][+-]?\d+)?')
        .matchAsPrefix(source, position);
    if (match == null) throw _error('Bad number');
    position = match.end;
    final text = match.group(0)!;
    if (match.group(1) == null && match.group(2) == null) {
      return int.tryParse(text) ?? double.parse(text);
    }
    return double.parse(text);
  }

  Map<String, Object?> _regex() {
    final start = position++;
    final pattern = StringBuffer();
    while (true) {
      if (position >= source.length || source[position] == '\n') {
        position = start;
        throw _error('Unterminated regular expression');
      }
      final c = source[position++];
      if (c == '/') break;
      pattern.write(c);
      if (c == r'\' && position < source.length) {
        pattern.write(source[position++]);
      }
    }
    final optionsStart = position;
    while (position < source.length && 'gimsuyx'.contains(source[position])) {
      position++;
    }
    return {
      r'$regularExpression': {
        'pattern': pattern.toString(),
        'options': source.substring(optionsStart, position),
      },
    };
  }

  Object? _word() {
    var word = _identifier();
    if (word == 'new') {
      skipTrivia();
      word = _identifier();
    }
    skipTrivia();
    if (_peek() != '(') {
      return switch (word) {
        'true' => true,
        'false' => false,
        'null' => null,
        'undefined' => {r'$undefined': true},
        _ => throw _error('Unknown word $word'),
      };
    }
    position++;
    final args = <Object?>[];
    while (true) {
      skipTrivia();
      if (_peek() == ')') {
        position++;
        break;
      }
      args.add(parseValue());
      skipTrivia();
      if (_peek() == ',') {
        position++;
      } else if (_peek() != ')') {
        throw _error('Expected , or )');
      }
    }
    return _construct(word, args);
  }

  Object? _construct(String name, List<Object?> a) {
    Object? arg(int i) => i < a.length ? a[i] : null;
    switch (name) {
      case 'ObjectId':
        return {r'$oid': '${arg(0)}'};
      case 'ISODate':
      case 'Date':
        final v = arg(0);
        if (v == null) {
          return {r'$date': DateTime.now().toUtc().toIso8601String()};
        }
        if (v is int) {
          return {
            r'$date': {r'$numberLong': '$v'},
          };
        }
        return {r'$date': '$v'};
      case 'NumberInt':
        return {r'$numberInt': '${arg(0)}'};
      case 'NumberLong':
        return {r'$numberLong': '${arg(0)}'};
      case 'NumberDecimal':
        return {r'$numberDecimal': '${arg(0)}'};
      case 'Double':
        return {r'$numberDouble': '${arg(0)}'};
      case 'UUID':
        return _uuid('${arg(0)}');
      case 'BinData':
        return {
          r'$binary': {
            'base64': '${arg(1)}',
            'subType': (arg(0) as int? ?? 0).toRadixString(16).padLeft(2, '0'),
          },
        };
      case 'Timestamp':
        return {
          r'$timestamp': {'t': arg(0), 'i': arg(1)},
        };
      case 'MinKey':
        return {r'$minKey': 1};
      case 'MaxKey':
        return {r'$maxKey': 1};
      case 'RegExp':
        return {
          r'$regularExpression': {
            'pattern': '${arg(0)}',
            'options': '${arg(1) ?? ''}',
          },
        };
      default:
        throw _error('Unknown constructor $name');
    }
  }

  Map<String, Object?> _uuid(String text) {
    final hex = text.replaceAll('-', '');
    if (hex.length != 32) throw _error('Bad UUID');
    final bytes = <int>[];
    for (var i = 0; i < 32; i += 2) {
      final b = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (b == null) throw _error('Bad UUID');
      bytes.add(b);
    }
    return {
      r'$binary': {'base64': base64Encode(bytes), 'subType': '04'},
    };
  }
}

class _Failed {
  const _Failed(this.text);
  final String text;
}

bool isFailedElement(Object? v) => v is _Failed;

String failedElementText(Object? v) => (v as _Failed).text;

bool _isDigit(String c) =>
    c.isNotEmpty && c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

bool _isIdentStart(String c) => RegExp(r'[A-Za-z_$]').hasMatch(c);

bool _isIdentPart(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);
