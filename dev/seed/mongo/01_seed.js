// Seed for the Queravue Mongo integration tests. Run with:
//   docker compose -f dev/docker-compose.yml --profile seed up mongo-seed
// Idempotent: drops and recreates the `queravue` database.
const qv = db.getSiblingDB('queravue');
qv.dropDatabase();

// users: nested objects, arrays, mixed types and missing fields.
qv.users.insertMany([
  {
    _id: ObjectId('650000000000000000000001'),
    name: 'Ada Lovelace', email: 'ada@example.com',
    age: NumberInt(36), visits: NumberLong('9007199254740993'), score: 98.5,
    balance: NumberDecimal('1234567890.1234567890'),
    joined: ISODate('2020-01-15T10:30:00Z'),
    session: UUID('0f8fad5b-d9cb-469f-a165-70867728950e'),
    avatar: BinData(0, 'aGVsbG8='),
    address: { city: 'London', geo: { lat: 51.5, lon: -0.12 }, tags: ['home', 'primary'] },
    roles: ['admin', 'dev'], nickname: null, active: true,
  },
  {
    _id: ObjectId('650000000000000000000002'),
    name: 'Alan Turing', email: 'alan@example.com',
    age: 41, visits: NumberLong('7'), score: NumberInt(77),
    joined: ISODate('2019-06-23T00:00:00Z'),
    address: { city: 'Wilmslow', tags: [] },
    roles: ['dev'], active: false, // nickname and balance are missing
  },
  {
    _id: 'string-id-3', name: 'Grace Hopper', email: null,
    age: '85', // mixed type on purpose
    visits: 0, joined: ISODate('1992-01-01T00:00:00Z'),
    address: null, roles: [], active: true, rank: 'Rear Admiral',
    pattern: /^grace/i, stamp: Timestamp(1700000000, 1), lo: MinKey(), hi: MaxKey(),
  },
  { _id: NumberInt(4), name: 'Edsger Dijkstra', email: 'ed@example.com', age: 72, active: true },
  { _id: NumberLong('5'), name: 'Barbara Liskov', email: 'barbara@example.com', age: 85, active: true },
]);
qv.users.createIndex({ email: 1 });

// orders: references users, nested line items.
const orders = [];
for (let i = 1; i <= 200; i++) {
  orders.push({
    _id: i, user: i % 2 ? ObjectId('650000000000000000000001') : ObjectId('650000000000000000000002'),
    status: ['new', 'paid', 'shipped', 'cancelled'][i % 4],
    total: NumberDecimal((i * 12.5).toFixed(2)),
    placed: new Date(Date.UTC(2024, i % 12, 1 + (i % 28))),
    items: [{ sku: 'SKU-' + i, qty: NumberInt(1 + (i % 3)), price: 12.5 }],
  });
}
qv.orders.insertMany(orders);
qv.orders.createIndex({ status: 1, placed: -1 });

// A view and a capped collection for the schema tree.
qv.createView('paid_orders', 'orders', [{ $match: { status: 'paid' } }]);
qv.createCollection('audit_log', { capped: true, size: 1048576 });
qv.audit_log.insertOne({ msg: 'seeded' });

// events: 1M documents generated server-side (100 x 10000), no client loop.
qv.aggregate([
  { $documents: [{}] },
  { $set: { a: { $range: [0, 100] } } }, { $unwind: '$a' },
  { $set: { b: { $range: [0, 10000] } } }, { $unwind: '$b' },
  { $project: { _id: 0, n: { $add: [{ $multiply: ['$a', 10000] }, '$b'] } } },
  { $set: {
      kind: { $arrayElemAt: [['click', 'view', 'buy', 'scroll'], { $mod: ['$n', 4] }] },
      user: { $mod: ['$n', 1000] },
      at: { $dateAdd: { startDate: ISODate('2024-01-01T00:00:00Z'), unit: 'second', amount: '$n' } },
      payload: { $concat: ['event-', { $toString: '$n' }] },
  } },
  { $out: 'events' },
]);
qv.events.createIndex({ n: 1 });
print('seeded: users=' + qv.users.countDocuments() + ' orders=' + qv.orders.countDocuments() +
      ' events=' + qv.events.estimatedDocumentCount());
