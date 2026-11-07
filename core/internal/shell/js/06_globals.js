var currentDb = databaseProxy(N.defaultDatabase());

function setPrint(level) {
  return function () { N.print(level, printText(arguments)); };
}

function formatSize(bytes) {
  var units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'], i = 0;
  while (bytes >= 1024 && i < units.length - 1) { bytes /= 1024; i++; }
  return (i === 0 ? bytes : bytes.toFixed(2)) + ' ' + units[i];
}

function padRight(s, n) {
  while (s.length < n) s += ' ';
  return s;
}

function showCommand(what) {
  switch (what) {
    case 'dbs': case 'databases':
      var res = runCmd('admin', { listDatabases: 1 });
      var rows = res.databases.slice().sort(function (a, b) { return a.name < b.name ? -1 : 1; });
      var width = Math.max.apply(null, rows.map(function (d) { return d.name.length; }).concat([0]));
      rows.forEach(function (d) { N.print('log', padRight(d.name, width) + '  ' + formatSize(Number(d.sizeOnDisk))); });
      return;
    case 'collections': case 'tables':
      currentDb.getCollectionNames().forEach(function (n) { N.print('log', n); });
      return;
  }
  throw unsupported('show ' + what);
}

function installGlobals(g) {
  Object.defineProperty(g, 'db', { get: function () { return currentDb; }, set: function (v) { currentDb = v; }, enumerable: true, configurable: true });
  var values = {
    ObjectId: ObjectId, ISODate: ISODate, NumberInt: Int32, NumberLong: Long, NumberDecimal: Decimal128, UUID: UUID,
    BinData: Binary, Timestamp: Timestamp, MinKey: MinKey, MaxKey: MaxKey, Long: Long, Int32: Int32, Decimal128: Decimal128,
    Double: Double, Binary: Binary, BSONRegExp: BSONRegExp,
    use: function (name) { currentDb = currentDb.getSiblingDB(name); N.print('log', 'switched to db ' + name); },
    show: showCommand,
    print: setPrint('log'),
    printjson: function (v) { N.print('log', shellText(v, true)); },
    tojson: function (v) { return shellText(v, true); },
    sleep: function (ms) { N.sleep(Number(ms)); },
    load: function () { throw unsupported('load()'); },
    require: function () { throw unsupported('require()'); },
    quit: function () { throw unsupported('quit()'); },
    exit: function () { throw unsupported('exit()'); }
  };
  Object.keys(values).forEach(function (k) {
    Object.defineProperty(g, k, { value: values[k], writable: true, enumerable: false, configurable: true });
  });
  var console = { log: setPrint('log'), info: setPrint('info'), warn: setPrint('warn'), error: setPrint('error'), debug: setPrint('log') };
  Object.defineProperty(g, 'console', { value: console, writable: true, enumerable: false, configurable: true });
}

function classify(v) {
  if (v === undefined) return null;
  if (typeof v === 'function') return v._isCollection ? { t: 'scalar', text: JSON.stringify(shellText(v)) } : null;
  if (v !== null && typeof v === 'object') {
    if (v._isCursor) return v._started() ? null : { t: 'cursor', text: v._specJSON() };
    if (v._isCollection || v._isDatabase) return { t: 'scalar', text: JSON.stringify(shellText(v)) };
    if (v.__op) return { t: 'write', op: v.__op, text: stringify(v) };
    if (isPlainObject(v)) return { t: 'doc', text: stringify(v) };
  }
  return { t: 'scalar', text: stringify(v) };
}

installGlobals(global);
N.setErrorFactory(makeError);
return classify;
