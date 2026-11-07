function shellText(v, pretty, level, seen) {
  level = level || 0;
  seen = seen || [];
  switch (typeof v) {
    case 'undefined': return 'undefined';
    case 'string': return JSON.stringify(v);
    case 'number': return v === 0 && 1 / v < 0 ? '-0' : String(v);
    case 'boolean': return String(v);
    case 'function': return v._isCollection ? v.getFullName() : '[Function: ' + (v.name || 'anonymous') + ']';
  }
  if (v === null) return 'null';
  if (v._bson) return v._t();
  if (v instanceof Date) return isNaN(v.getTime()) ? 'Invalid Date' : 'ISODate("' + v.toISOString() + '")';
  if (v instanceof RegExp) return String(v);
  if (v instanceof Error) return v.name + ': ' + v.message;
  if (v._isCollection) return v.getFullName();
  if (v._isDatabase) return v.getName();
  if (v._isCursor) return 'Cursor';
  if (seen.indexOf(v) >= 0) return '[Circular]';
  seen.push(v);
  var inner = (pretty ? '\n' + indent(level + 1) : ' ');
  var close = (pretty ? '\n' + indent(level) : ' ');
  var out;
  if (Array.isArray(v)) {
    out = v.length === 0 ? '[]' : '[' + inner + v.map(function (x) { return shellText(x, pretty, level + 1, seen); }).join(',' + inner) + close + ']';
  } else {
    var keys = Object.keys(v);
    out = keys.length === 0 ? '{}' : '{' + inner + keys.map(function (k) {
      return JSON.stringify(k) + ': ' + shellText(v[k], pretty, level + 1, seen);
    }).join(',' + inner) + close + '}';
  }
  seen.pop();
  return out;
}

function indent(n) {
  var s = '';
  for (var i = 0; i < n; i++) s += '  ';
  return s;
}

function printText(args) {
  var out = [];
  for (var i = 0; i < args.length; i++) out.push(typeof args[i] === 'string' ? args[i] : shellText(args[i], false));
  return out.join(' ');
}
