var WRITE_COMMANDS = ['insert', 'update', 'delete', 'findAndModify', 'findandmodify', 'drop', 'dropDatabase', 'create', 'createIndexes',
  'dropIndexes', 'renameCollection', 'collMod', 'convertToCapped', 'compact', 'reIndex', 'applyOps', 'createUser', 'updateUser',
  'dropUser', 'dropAllUsersFromDatabase', 'createRole', 'updateRole', 'dropRole', 'grantRolesToUser', 'revokeRolesFromUser',
  'setParameter', 'shutdown', 'killOp', 'fsync', 'fsyncUnlock', 'replSetReconfig', 'replSetStepDown', 'moveChunk', 'shardCollection'];

function commandName(cmd) {
  var keys = Object.keys(cmd);
  return keys.length ? keys[0] : '';
}

function runCmd(dbName, cmd) {
  return parse(N.cmd(dbName, stringify(cmd)));
}

function writeErrorOf(res) {
  if (res.writeErrors && res.writeErrors.length) {
    var w = res.writeErrors[0];
    return makeError('MongoServerError', w.errmsg, w.code, 'server');
  }
  return null;
}

function checkWrite(res) {
  var err = writeErrorOf(res);
  if (err) throw err;
  return res;
}

function result(op, obj) {
  hidden(obj, '__op', op);
  return obj;
}

function isEmptyFilter(f) {
  return f === undefined || f === null || (typeof f === 'object' && !Array.isArray(f) && Object.keys(f).length === 0);
}

function requireDocument(v, what) {
  if (v === null || typeof v !== 'object' || Array.isArray(v)) throw new Error(what + ' must be an object');
  return v;
}

function Collection(database, name) {
  hidden(this, '_isCollection', true);
  hidden(this, '_database', database);
  hidden(this, '_name', name);
}

function collectionProxy(database, name) {
  return new Proxy(new Collection(database, name), {
    get: function (target, prop) {
      if (typeof prop === 'symbol' || prop in target) return target[prop];
      if (prop[0] === '_') return undefined;
      return subCollection(database, name + '.' + prop);
    }
  });
}

function subCollection(database, name) {
  var collection = collectionProxy(database, name);
  var notAFunction = function () { throw makeError('TypeError', 'db.' + name + ' is not a function', 0, 'unsupported'); };
  return new Proxy(notAFunction, {
    get: function (target, prop) { return collection[prop]; },
    has: function (target, prop) { return prop in collection; }
  });
}

function C(name, fn) { hidden(Collection.prototype, name, fn); }

C('getName', function () { return this._name; });
C('getFullName', function () { return this._database._name + '.' + this._name; });
C('getDB', function () { return this._database; });

C('find', function (filter, projection, options) {
  var o = Object.assign({}, options || {});
  o.filter = filter || {};
  if (projection) o.projection = projection;
  return new Cursor('find', this._database._name, this._name, o);
});

C('findOne', function (filter, projection, options) {
  var o = Object.assign({}, options || {}, { filter: filter || {}, limit: 1 });
  if (projection) o.projection = projection;
  var c = new Cursor('find', this._database._name, this._name, o);
  var d = c._take(false);
  c.close();
  return d === NONE ? null : d;
});

C('countDocuments', function (filter, options) {
  return countDocuments(this._database._name, this._name, filter, options);
});

C('estimatedDocumentCount', function () {
  return runCmd(this._database._name, { count: this._name }).n;
});

C('distinct', function (field, query) {
  var cmd = { distinct: this._name, key: field };
  if (query) cmd.query = query;
  return runCmd(this._database._name, cmd).values;
});

C('aggregate', function (pipeline, options) {
  if (!Array.isArray(pipeline)) throw new Error('aggregate() requires an array of pipeline stages');
  var o = Object.assign({}, options || {}, { pipeline: pipeline });
  var cursor = new Cursor('aggregate', this._database._name, this._name, o);
  var last = pipeline.length ? commandName(pipeline[pipeline.length - 1]) : '';
  if (last === '$out' || last === '$merge') {
    N.gate('aggregate with ' + last + ' on ' + this.getFullName(), false);
    cursor.itcount();
    return new Cursor('aggregate', this._database._name, this._name, { pipeline: [{ $limit: 0 }] });
  }
  return cursor;
});

function insertDocs(coll, docs, ordered) {
  var ids = {}, prepared = docs.map(function (d, i) {
    requireDocument(d, 'document');
    if (d._id === undefined) d = Object.assign({ _id: ObjectId() }, d);
    ids[String(i)] = d._id;
    return d;
  });
  var cmd = { insert: coll._name, documents: prepared };
  if (ordered === false) cmd.ordered = false;
  checkWrite(runCmd(coll._database._name, cmd));
  return ids;
}

C('insertOne', function (doc) {
  var ids = insertDocs(this, [doc]);
  return result('insertOne', { acknowledged: true, insertedId: ids['0'] });
});

C('insertMany', function (docs, options) {
  if (!Array.isArray(docs)) throw new Error('insertMany() requires an array of documents');
  var ids = insertDocs(this, docs, options && options.ordered);
  return result('insertMany', { acknowledged: true, insertedIds: ids });
});

function requireOperators(update) {
  if (Array.isArray(update)) return;
  var keys = Object.keys(requireDocument(update, 'update'));
  if (!keys.length || keys[0][0] !== '$') throw new Error('Update document requires atomic operators');
}

function runUpdate(coll, filter, update, options, multi) {
  var stmt = { q: filter || {}, u: update, multi: multi };
  options = options || {};
  ['upsert', 'arrayFilters', 'hint', 'collation'].forEach(function (k) { if (options[k] !== undefined) stmt[k] = options[k]; });
  var res = checkWrite(runCmd(coll._database._name, { update: coll._name, updates: [stmt] }));
  var upserted = res.upserted && res.upserted.length ? res.upserted[0]._id : null;
  return { matched: res.n - (upserted === null ? 0 : 1), modified: res.nModified, upsertedId: upserted };
}

function updateResult(op, r) {
  return result(op, { acknowledged: true, insertedId: r.upsertedId, matchedCount: r.matched, modifiedCount: r.modified, upsertedCount: r.upsertedId === null ? 0 : 1 });
}

C('updateOne', function (filter, update, options) {
  requireOperators(update);
  return updateResult('updateOne', runUpdate(this, filter, update, options, false));
});

C('updateMany', function (filter, update, options) {
  requireOperators(update);
  if (isEmptyFilter(filter)) N.gate('updateMany({}) on ' + this.getFullName(), false);
  return updateResult('updateMany', runUpdate(this, filter, update, options, true));
});

C('replaceOne', function (filter, replacement, options) {
  var keys = Object.keys(requireDocument(replacement, 'replacement'));
  if (keys.length && keys[0][0] === '$') throw new Error('Replacement document must not contain atomic operators');
  return updateResult('replaceOne', runUpdate(this, filter, replacement, options, false));
});

function runDelete(coll, filter, limit) {
  var res = checkWrite(runCmd(coll._database._name, { delete: coll._name, deletes: [{ q: filter || {}, limit: limit }] }));
  return res.n;
}

C('deleteOne', function (filter) {
  return result('deleteOne', { acknowledged: true, deletedCount: runDelete(this, filter, 1) });
});

C('deleteMany', function (filter) {
  if (isEmptyFilter(filter)) N.gate('deleteMany({}) on ' + this.getFullName(), false);
  return result('deleteMany', { acknowledged: true, deletedCount: runDelete(this, filter, 0) });
});

function findAndModify(coll, filter, options, change) {
  var cmd = Object.assign({ findAndModify: coll._name, query: filter || {} }, change);
  options = options || {};
  if (options.sort) cmd.sort = options.sort;
  if (options.projection) cmd.fields = options.projection;
  if (options.upsert) cmd.upsert = true;
  if (options.returnDocument === 'after') cmd.new = true;
  if (options.arrayFilters) cmd.arrayFilters = options.arrayFilters;
  var res = runCmd(coll._database._name, cmd);
  return res.value === undefined ? null : res.value;
}

C('findOneAndUpdate', function (filter, update, options) {
  requireOperators(update);
  return findAndModify(this, filter, options, { update: update });
});

C('findOneAndReplace', function (filter, replacement, options) {
  return findAndModify(this, filter, options, { update: requireDocument(replacement, 'replacement') });
});

C('findOneAndDelete', function (filter, options) {
  return findAndModify(this, filter, options, { remove: true });
});

C('bulkWrite', function (ops, options) {
  if (!Array.isArray(ops)) throw new Error('bulkWrite() requires an array of operations');
  var out = { acknowledged: true, insertedCount: 0, matchedCount: 0, modifiedCount: 0, deletedCount: 0, upsertedCount: 0, insertedIds: {}, upsertedIds: {} };
  var self = this;
  ops.forEach(function (op, i) {
    var name = commandName(op), a = op[name];
    switch (name) {
      case 'insertOne':
        out.insertedIds[String(i)] = insertDocs(self, [a.document])['0'];
        out.insertedCount++;
        break;
      case 'updateOne': case 'updateMany': case 'replaceOne': {
        if (name === 'replaceOne') a = { filter: a.filter, update: a.replacement, upsert: a.upsert };
        if (name === 'updateMany' && isEmptyFilter(a.filter)) N.gate('bulkWrite updateMany({}) on ' + self.getFullName(), false);
        var r = runUpdate(self, a.filter, a.update, a, name === 'updateMany');
        out.matchedCount += r.matched;
        out.modifiedCount += r.modified;
        if (r.upsertedId !== null) { out.upsertedCount++; out.upsertedIds[String(i)] = r.upsertedId; }
        break;
      }
      case 'deleteOne': out.deletedCount += runDelete(self, a.filter, 1); break;
      case 'deleteMany':
        if (isEmptyFilter(a.filter)) N.gate('bulkWrite deleteMany({}) on ' + self.getFullName(), false);
        out.deletedCount += runDelete(self, a.filter, 0);
        break;
      default: throw unsupported('bulkWrite operation ' + name);
    }
  });
  return result('bulkWrite', out);
});

function indexName(keys) {
  return Object.keys(keys).map(function (k) { return k + '_' + String(keys[k]); }).join('_');
}

C('createIndex', function (keys, options) {
  requireDocument(keys, 'index keys');
  var spec = Object.assign({ key: keys, name: indexName(keys) }, options || {});
  runCmd(this._database._name, { createIndexes: this._name, indexes: [spec] });
  return spec.name;
});

C('getIndexes', function () {
  return runCmd(this._database._name, { listIndexes: this._name }).cursor.firstBatch;
});

C('dropIndex', function (index) {
  return runCmd(this._database._name, { dropIndexes: this._name, index: typeof index === 'string' ? index : index });
});

C('drop', function () {
  N.gate('drop ' + this.getFullName(), false);
  try {
    runCmd(this._database._name, { drop: this._name });
    return true;
  } catch (e) {
    if (e.code === 26) return false;
    throw e;
  }
});

C('renameCollection', function (target, dropTarget) {
  if (dropTarget) N.gate('renameCollection onto ' + target + ' with dropTarget', false);
  var db = this._database._name;
  return runCmd('admin', { renameCollection: db + '.' + this._name, to: db + '.' + target, dropTarget: !!dropTarget });
});

C('stats', function () { return runCmd(this._database._name, { collStats: this._name }); });

function Database(name) {
  hidden(this, '_isDatabase', true);
  hidden(this, '_name', name);
}

function databaseProxy(name) {
  return new Proxy(new Database(name), {
    get: function (target, prop) {
      if (typeof prop === 'symbol' || prop in target) return target[prop];
      if (prop[0] === '_') return undefined;
      return target.getCollection(prop);
    }
  });
}

function D(name, fn) { hidden(Database.prototype, name, fn); }

D('getName', function () { return this._name; });
D('getSiblingDB', function (name) { return databaseProxy(String(name)); });
D('getCollection', function (name) { return collectionProxy(this, String(name)); });

D('runCommand', function (cmd) {
  if (typeof cmd === 'string') cmd = (function (n) { var o = {}; o[n] = 1; return o; })(cmd);
  var name = commandName(requireDocument(cmd, 'command'));
  if (WRITE_COMMANDS.indexOf(name) >= 0) N.gate('runCommand ' + name + ' on ' + this._name, false);
  return runCmd(this._name, cmd);
});

D('adminCommand', function (cmd) { return databaseProxy('admin').runCommand(cmd); });

D('getCollectionNames', function () {
  var res = runCmd(this._name, { listCollections: 1, nameOnly: true, cursor: { batchSize: 100000 } });
  return res.cursor.firstBatch.map(function (c) { return c.name; }).sort();
});

D('stats', function (scale) { return runCmd(this._name, { dbStats: 1, scale: scale || 1 }); });
D('version', function () { return runCmd('admin', { buildInfo: 1 }).version; });
D('serverStatus', function () { return runCmd('admin', { serverStatus: 1 }); });

D('createCollection', function (name, options) {
  var cmd = Object.assign({ create: String(name) }, options || {});
  runCmd(this._name, cmd);
  return { ok: 1 };
});

D('dropDatabase', function () {
  N.gate('dropDatabase ' + this._name, true);
  return runCmd(this._name, { dropDatabase: 1 });
});
