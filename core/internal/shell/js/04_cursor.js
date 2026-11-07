var DEFAULT_BATCH = 500;

function Cursor(kind, dbName, collName, opts) {
  hidden(this, '_isCursor', true);
  hidden(this, '_kind', kind);
  hidden(this, '_db', dbName);
  hidden(this, '_coll', collName);
  hidden(this, '_o', opts || {});
  hidden(this, '_id', null);
  hidden(this, '_buf', []);
  hidden(this, '_pos', 0);
  hidden(this, '_done', false);
  hidden(this, '_maps', []);
}

function mod(name, field, convert) {
  hidden(Cursor.prototype, name, function (v) {
    if (this._id !== null) throw new Error('Cursor is already started, cannot call ' + name + '()');
    this._o[field] = convert ? convert(v) : v;
    return this;
  });
}

function positiveInt(v) { return Math.abs(Math.trunc(Number(v))); }

mod('limit', 'limit', positiveInt);
mod('skip', 'skip', positiveInt);
mod('sort', 'sort');
mod('project', 'projection');
mod('projection', 'projection');
mod('batchSize', 'batchSize', positiveInt);
mod('hint', 'hint');
mod('maxTimeMS', 'maxTimeMS', positiveInt);
mod('allowDiskUse', 'allowDiskUse');
mod('collation', 'collation');
mod('comment', 'comment');
mod('min', 'min');
mod('max', 'max');

function specObject(c) {
  var o = c._o;
  var spec = { kind: c._kind, database: c._db, collection: c._coll, skip: o.skip || 0, limit: o.limit || 0, batchSize: o.batchSize || 0, maxTimeMS: o.maxTimeMS || 0 };
  if (c._kind === 'aggregate') spec.pipeline = stringify(o.pipeline || []);
  else {
    spec.filter = stringify(o.filter || {});
    spec.sort = o.sort ? stringify(o.sort) : '';
    spec.projection = o.projection ? stringify(o.projection) : '';
  }
  spec.hint = o.hint ? stringify(o.hint) : '';
  return spec;
}

hidden(Cursor.prototype, '_specJSON', function () { return JSON.stringify(specObject(this)); });
hidden(Cursor.prototype, '_started', function () { return this._id !== null; });

hidden(Cursor.prototype, '_open', function () {
  if (this._id === null) this._id = N.cursorOpen(this._specJSON());
});

hidden(Cursor.prototype, '_fill', function (retain) {
  while (this._pos >= this._buf.length && !this._done) {
    this._open();
    var reply = N.cursorNext(this._id, this._o.batchSize || DEFAULT_BATCH, !!retain);
    var docs = JSON.parse(reply[0]);
    for (var i = 0; i < docs.length; i++) docs[i] = revive(docs[i]);
    this._buf = docs;
    this._pos = 0;
    if (reply[1]) this._done = true;
  }
});

hidden(Cursor.prototype, '_take', function (retain) {
  this._fill(retain);
  if (this._pos >= this._buf.length) return NONE;
  var doc = this._buf[this._pos++];
  for (var i = 0; i < this._maps.length; i++) doc = this._maps[i](doc);
  return doc;
});

var NONE = {};

hidden(Cursor.prototype, 'hasNext', function () {
  this._fill(false);
  return this._pos < this._buf.length;
});

hidden(Cursor.prototype, 'next', function () {
  var d = this._take(false);
  if (d === NONE) throw makeError('MongoshInvalidInputError', 'Cursor is exhausted', 0);
  return d;
});

hidden(Cursor.prototype, 'tryNext', function () {
  var d = this._take(false);
  return d === NONE ? null : d;
});

hidden(Cursor.prototype, 'toArray', function () {
  var out = [], d;
  while ((d = this._take(true)) !== NONE) out.push(d);
  this.close();
  return out;
});

hidden(Cursor.prototype, 'forEach', function (fn) {
  var d;
  while ((d = this._take(false)) !== NONE) fn(d);
  this.close();
});

hidden(Cursor.prototype, 'map', function (fn) {
  this._maps.push(fn);
  return this;
});

hidden(Cursor.prototype, 'itcount', function () {
  var n = 0;
  while (this._take(false) !== NONE) n++;
  this.close();
  return n;
});

hidden(Cursor.prototype, 'pretty', function () { return this; });
hidden(Cursor.prototype, 'objsLeftInBatch', function () { return Math.max(0, this._buf.length - this._pos); });
hidden(Cursor.prototype, 'isClosed', function () { return this._done && this._pos >= this._buf.length; });
hidden(Cursor.prototype, 'isExhausted', function () { return !this.hasNext(); });

hidden(Cursor.prototype, 'close', function () {
  if (this._id !== null) N.cursorClose(this._id);
  this._done = true;
  this._buf = [];
  this._pos = 0;
});

hidden(Cursor.prototype, 'count', function () {
  if (this._kind !== 'find') throw unsupported('count() on an aggregation cursor');
  var res = parse(N.cmd(this._db, stringify({ count: this._coll, query: this._o.filter || {} })));
  return res.n;
});

hidden(Cursor.prototype, 'size', function () {
  if (this._kind !== 'find') throw unsupported('size() on an aggregation cursor');
  return countDocuments(this._db, this._coll, this._o.filter || {}, { skip: this._o.skip, limit: this._o.limit });
});

hidden(Cursor.prototype, 'explain', function (verbosity) {
  var o = this._o, body;
  if (this._kind === 'aggregate') {
    body = { aggregate: this._coll, pipeline: o.pipeline || [], cursor: {} };
  } else {
    body = { find: this._coll, filter: o.filter || {} };
    if (o.sort) body.sort = o.sort;
    if (o.projection) body.projection = o.projection;
    if (o.skip) body.skip = o.skip;
    if (o.limit) body.limit = o.limit;
    if (o.hint) body.hint = o.hint;
  }
  return parse(N.cmd(this._db, stringify({ explain: body, verbosity: verbosity || 'queryPlanner' })));
});

function countDocuments(dbName, collName, filter, opts) {
  opts = opts || {};
  var pipeline = [{ $match: filter || {} }];
  if (opts.skip) pipeline.push({ $skip: opts.skip });
  if (opts.limit) pipeline.push({ $limit: opts.limit });
  pipeline.push({ $group: { _id: 1, n: { $sum: 1 } } });
  var rows = new Cursor('aggregate', dbName, collName, { pipeline: pipeline }).toArray();
  var n = rows.length ? rows[0].n : 0;
  return n && n._bson === 'Long' ? n.toNumber() : n;
}
