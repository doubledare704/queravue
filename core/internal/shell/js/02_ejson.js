var MAX_DEPTH = 200;

function isPlainObject(v) {
  return Object.prototype.toString.call(v) === '[object Object]' && !v._bson;
}

function numberText(n) {
  if (n !== n || n === Infinity || n === -Infinity || (n === 0 && 1 / n < 0)) return '{"$numberDouble":"' + doubleText(n) + '"}';
  if (Math.floor(n) === n && n >= -2147483648 && n <= 2147483647) return '{"$numberInt":"' + n + '"}';
  return '{"$numberDouble":"' + doubleText(n) + '"}';
}

function stringify(v, depth) {
  depth = depth || 0;
  if (depth > MAX_DEPTH) throw new RangeError('Maximum document nesting depth exceeded');
  switch (typeof v) {
    case 'undefined': return 'null';
    case 'boolean': return v ? 'true' : 'false';
    case 'string': return JSON.stringify(v);
    case 'number': return numberText(v);
    case 'function': return 'null';
  }
  if (v === null) return 'null';
  if (v._bson) return v._e();
  if (v instanceof Date) {
    var ms = v.getTime();
    if (isNaN(ms)) throw new Error('Invalid Date cannot be stored');
    return '{"$date":{"$numberLong":"' + ms + '"}}';
  }
  if (v instanceof RegExp) {
    var opts = '';
    if (v.ignoreCase) opts += 'i';
    if (v.multiline) opts += 'm';
    if (v.dotAll) opts += 's';
    return '{"$regularExpression":{"pattern":' + JSON.stringify(v.source) + ',"options":"' + opts + '"}}';
  }
  if (Array.isArray(v)) {
    var items = [];
    for (var i = 0; i < v.length; i++) items.push(stringify(v[i], depth + 1));
    return '[' + items.join(',') + ']';
  }
  if (v._isCollection || v._isCursor || v._isDatabase) throw new Error('Cannot store a ' + (v._isCursor ? 'cursor' : 'collection') + ' in a document');
  var parts = [];
  Object.keys(v).forEach(function (k) {
    if (typeof v[k] === 'function') return;
    parts.push(JSON.stringify(k) + ':' + stringify(v[k], depth + 1));
  });
  return '{' + parts.join(',') + '}';
}

function revive(v) {
  if (v === null || typeof v !== 'object') return v;
  if (Array.isArray(v)) {
    for (var i = 0; i < v.length; i++) {
      var x = v[i];
      if (x !== null && typeof x === 'object') v[i] = revive(x);
    }
    return v;
  }
  var keys = Object.keys(v);
  if (keys.length >= 1 && keys[0][0] === '$') {
    var typed = reviveWrapper(v, keys);
    if (typed !== NOT_WRAPPER) return typed;
  }
  for (var j = 0; j < keys.length; j++) {
    var y = v[keys[j]];
    if (y !== null && typeof y === 'object') v[keys[j]] = revive(y);
  }
  return v;
}

var NOT_WRAPPER = {};

function reviveWrapper(v, keys) {
  var k = keys[0];
  if (keys.length === 1) {
    switch (k) {
      case '$oid': return ObjectId(v.$oid);
      case '$numberInt': return Number(v.$numberInt);
      case '$numberLong': return Long(v.$numberLong);
      case '$numberDouble': return Number(v.$numberDouble.replace('Infinity', 'Infinity'));
      case '$numberDecimal': return Decimal128(v.$numberDecimal);
      case '$date': {
        var d = v.$date;
        return new Date(typeof d === 'object' ? Number(d.$numberLong) : d);
      }
      case '$minKey': return MinKey();
      case '$maxKey': return MaxKey();
      case '$undefined': return null;
      case '$symbol': return v.$symbol;
      case '$timestamp': return Timestamp(v.$timestamp.t, v.$timestamp.i);
      case '$regularExpression': return reviveRegExp(v.$regularExpression.pattern, v.$regularExpression.options);
      case '$binary':
        return v.$binary.subType === '04'
          ? UUID(bytesToHex(b64ToBytes(v.$binary.base64)))
          : Binary(parseInt(v.$binary.subType, 16), v.$binary.base64);
    }
  }
  return NOT_WRAPPER;
}

function reviveRegExp(pattern, options) {
  var flags = '';
  if (options.indexOf('i') >= 0) flags += 'i';
  if (options.indexOf('m') >= 0) flags += 'm';
  if (options.indexOf('s') >= 0) flags += 's';
  if (options.replace(/[ims]/g, '') !== '') return BSONRegExp(pattern, options);
  try { return new RegExp(pattern, flags); } catch (e) { return BSONRegExp(pattern, options); }
}

function parse(text) {
  return revive(JSON.parse(text));
}
