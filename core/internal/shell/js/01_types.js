var global = this;

function hidden(o, k, v) {
  Object.defineProperty(o, k, { value: v, enumerable: false, writable: true, configurable: true });
}

function makeError(name, message, code, kind) {
  var e = new Error(message);
  e.name = name;
  if (code !== undefined && code !== 0) e.code = code;
  if (kind) hidden(e, 'kind', kind);
  return e;
}

function unsupported(what) {
  return makeError('MongoshUnsupportedError', what + ' is not supported by the Queravue shell', 0, 'unsupported');
}

function defType(name, init, methods) {
  function T() {
    var self = this instanceof T ? this : Object.create(T.prototype);
    init.apply(self, arguments);
    return self;
  }
  T.prototype = Object.create(Object.prototype);
  hidden(T.prototype, 'constructor', T);
  hidden(T.prototype, '_bson', name);
  Object.keys(methods).forEach(function (k) { hidden(T.prototype, k, methods[k]); });
  return T;
}

var B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function bytesToB64(bytes) {
  var out = '';
  for (var i = 0; i < bytes.length; i += 3) {
    var a = bytes[i], b = bytes[i + 1], c = bytes[i + 2];
    out += B64[a >> 2] + B64[((a & 3) << 4) | ((b || 0) >> 4)];
    out += i + 1 < bytes.length ? B64[((b & 15) << 2) | ((c || 0) >> 6)] : '=';
    out += i + 2 < bytes.length ? B64[c & 63] : '=';
  }
  return out;
}

function b64ToBytes(s) {
  var bytes = [], buf = 0, bits = 0;
  for (var i = 0; i < s.length; i++) {
    if (s[i] === '=') break;
    var v = B64.indexOf(s[i]);
    if (v < 0) throw new Error('Invalid base64 string');
    buf = (buf << 6) | v;
    bits += 6;
    if (bits >= 8) { bits -= 8; bytes.push((buf >> bits) & 255); }
  }
  return bytes;
}

function hexToBytes(h) {
  var bytes = [];
  for (var i = 0; i < h.length; i += 2) bytes.push(parseInt(h.substr(i, 2), 16));
  return bytes;
}

function bytesToHex(bytes) {
  return bytes.map(function (b) { return (b < 16 ? '0' : '') + b.toString(16); }).join('');
}

var INT64_MAX = '9223372036854775807';
var INT64_MIN = '9223372036854775808';

function inInt64(digits, negative) {
  var limit = negative ? INT64_MIN : INT64_MAX;
  return digits.length < limit.length || (digits.length === limit.length && digits <= limit);
}

var ObjectId = defType('ObjectId', function (h) {
  if (h === undefined) h = N.newOid();
  else if (h && h._bson === 'ObjectId') h = h._h;
  if (typeof h !== 'string' || !/^[0-9a-fA-F]{24}$/.test(h)) {
    throw new Error('Argument passed in must be a string of 12 bytes or a string of 24 hex characters');
  }
  hidden(this, '_h', h.toLowerCase());
}, {
  toString: function () { return this._h; },
  toHexString: function () { return this._h; },
  toJSON: function () { return this._h; },
  getTimestamp: function () { return new Date(parseInt(this._h.substr(0, 8), 16) * 1000); },
  equals: function (o) { return !!o && o._bson === 'ObjectId' && o._h === this._h; },
  _e: function () { return '{"$oid":"' + this._h + '"}'; },
  _t: function () { return 'ObjectId("' + this._h + '")'; }
});

var Long = defType('Long', function (v) {
  var s;
  if (v && v._bson === 'Long') s = v._s;
  else if (typeof v === 'number') {
    if (!isFinite(v)) throw new Error('NumberLong requires a finite number');
    s = String(Math.trunc(v));
    if (/e/i.test(s)) throw new Error('NumberLong value out of range: ' + v);
  } else if (typeof v === 'string' && /^-?\d+$/.test(v)) s = v.replace(/^(-?)0+(?=\d)/, '$1');
  else throw new Error('NumberLong requires a number or a decimal string');
  var neg = s[0] === '-';
  if (!inInt64(neg ? s.slice(1) : s, neg)) throw new Error('NumberLong value out of range: ' + s);
  hidden(this, '_s', s === '-0' ? '0' : s);
}, {
  toString: function () { return this._s; },
  toNumber: function () { return Number(this._s); },
  valueOf: function () { return Number(this._s); },
  toJSON: function () { return { $numberLong: this._s }; },
  equals: function (o) { return !!o && o._bson === 'Long' && o._s === this._s; },
  _e: function () { return '{"$numberLong":"' + this._s + '"}'; },
  _t: function () { return 'NumberLong("' + this._s + '")'; }
});

var Int32 = defType('Int32', function (v) {
  var n = Number(v && v._bson === 'Int32' ? v._n : v);
  if (!isFinite(n)) throw new Error('NumberInt requires a finite number');
  n = Math.trunc(n);
  if (n > 2147483647 || n < -2147483648) throw new Error('NumberInt value out of range: ' + n);
  hidden(this, '_n', n);
}, {
  toString: function () { return String(this._n); },
  valueOf: function () { return this._n; },
  toJSON: function () { return this._n; },
  _e: function () { return '{"$numberInt":"' + this._n + '"}'; },
  _t: function () { return 'NumberInt(' + this._n + ')'; }
});

var Double = defType('Double', function (v) {
  var n = Number(v && v._bson === 'Double' ? v._n : v);
  if (isNaN(n) && !(typeof v === 'number')) throw new Error('Double requires a number');
  hidden(this, '_n', n);
}, {
  toString: function () { return String(this._n); },
  valueOf: function () { return this._n; },
  toJSON: function () { return this._n; },
  _e: function () { return '{"$numberDouble":"' + doubleText(this._n) + '"}'; },
  _t: function () { return 'Double(' + doubleText(this._n) + ')'; }
});

function doubleText(n) {
  if (n !== n) return 'NaN';
  if (n === Infinity) return 'Infinity';
  if (n === -Infinity) return '-Infinity';
  if (n === 0 && 1 / n < 0) return '-0.0';
  var s = String(n);
  return /^-?\d+$/.test(s) ? s + '.0' : s;
}

var DECIMAL_RE = /^[+-]?((\d+\.?\d*|\.\d+)([eE][+-]?\d+)?|Infinity|inf|NaN)$/i;

var Decimal128 = defType('Decimal128', function (v) {
  var s = v && v._bson === 'Decimal128' ? v._s : String(v);
  if (!DECIMAL_RE.test(s)) throw new Error('NumberDecimal requires a decimal string, got: ' + s);
  hidden(this, '_s', s);
}, {
  toString: function () { return this._s; },
  toJSON: function () { return { $numberDecimal: this._s }; },
  _e: function () { return '{"$numberDecimal":' + JSON.stringify(this._s) + '}'; },
  _t: function () { return 'NumberDecimal("' + this._s + '")'; }
});

var Binary = defType('Binary', function (subtype, b64) {
  if (typeof subtype !== 'number' || subtype < 0 || subtype > 255) throw new Error('BinData subtype must be a number from 0 to 255');
  if (typeof b64 !== 'string') throw new Error('BinData requires a base64 string');
  b64ToBytes(b64);
  hidden(this, '_sub', subtype);
  hidden(this, '_b64', b64);
}, {
  base64: function () { return this._b64; },
  hex: function () { return bytesToHex(b64ToBytes(this._b64)); },
  length: function () { return b64ToBytes(this._b64).length; },
  toString: function () { return this._b64; },
  toJSON: function () { return { $binary: { base64: this._b64, subType: hex2(this._sub) } }; },
  _e: function () { return '{"$binary":{"base64":"' + this._b64 + '","subType":"' + hex2(this._sub) + '"}}'; },
  _t: function () { return 'BinData(' + this._sub + ',"' + this._b64 + '")'; }
});

function hex2(n) { return (n < 16 ? '0' : '') + n.toString(16); }

var UUID = defType('UUID', function (v) {
  if (v === undefined) v = N.newUUID();
  else if (v && v._bson === 'UUID') v = v._u;
  if (typeof v !== 'string') throw new Error('UUID requires a hex string');
  var h = v.replace(/-/g, '').toLowerCase();
  if (!/^[0-9a-f]{32}$/.test(h)) throw new Error('UUID requires 32 hex characters');
  hidden(this, '_u', h.substr(0, 8) + '-' + h.substr(8, 4) + '-' + h.substr(12, 4) + '-' + h.substr(16, 4) + '-' + h.substr(20));
}, {
  toString: function () { return this._u; },
  toHexString: function (dashes) { return dashes === false ? this._u.replace(/-/g, '') : this._u; },
  toJSON: function () { return this._u; },
  equals: function (o) { return !!o && o._bson === 'UUID' && o._u === this._u; },
  _e: function () { return '{"$binary":{"base64":"' + bytesToB64(hexToBytes(this._u.replace(/-/g, ''))) + '","subType":"04"}}'; },
  _t: function () { return 'UUID("' + this._u + '")'; }
});

var Timestamp = defType('Timestamp', function (t, i) {
  if (t && typeof t === 'object' && t._bson !== 'Timestamp') { i = t.i; t = t.t; }
  else if (t && t._bson === 'Timestamp') { i = t._i; t = t._t0; }
  t = Number(t); i = Number(i);
  if (!(t >= 0 && t <= 4294967295 && i >= 0 && i <= 4294967295)) throw new Error('Timestamp requires t and i between 0 and 4294967295');
  hidden(this, '_t0', Math.trunc(t));
  hidden(this, '_i', Math.trunc(i));
}, {
  toString: function () { return 'Timestamp(' + this._t0 + ', ' + this._i + ')'; },
  toJSON: function () { return { $timestamp: { t: this._t0, i: this._i } }; },
  _e: function () { return '{"$timestamp":{"t":' + this._t0 + ',"i":' + this._i + '}}'; },
  _t: function () { return 'Timestamp(' + this._t0 + ', ' + this._i + ')'; }
});

var MinKey = defType('MinKey', function () {}, {
  toJSON: function () { return { $minKey: 1 }; },
  _e: function () { return '{"$minKey":1}'; },
  _t: function () { return 'MinKey()'; }
});

var MaxKey = defType('MaxKey', function () {}, {
  toJSON: function () { return { $maxKey: 1 }; },
  _e: function () { return '{"$maxKey":1}'; },
  _t: function () { return 'MaxKey()'; }
});

var BSONRegExp = defType('BSONRegExp', function (pattern, options) {
  hidden(this, '_p', String(pattern));
  hidden(this, '_o', String(options || ''));
}, {
  toString: function () { return '/' + this._p + '/' + this._o; },
  _e: function () { return '{"$regularExpression":{"pattern":' + JSON.stringify(this._p) + ',"options":' + JSON.stringify(this._o) + '}}'; },
  _t: function () { return '/' + this._p + '/' + this._o; }
});

function ISODate(s) {
  if (s === undefined) return new Date();
  if (s instanceof Date) return new Date(s.getTime());
  if (typeof s === 'number') return new Date(s);
  var str = String(s);
  if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d+)?)?$/.test(str)) str += 'Z';
  var d = new Date(str);
  if (isNaN(d.getTime())) throw new Error('Invalid Date: ' + s);
  return d;
}
