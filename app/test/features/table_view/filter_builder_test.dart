import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/table_view/domain/table_models.dart';

void main() {
  group('Filter model and WHERE preview round-trip', () {
    test('empty filter produces empty preview', () {
      const filter = TableFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.toWherePreview(), isEmpty);
    });

    test('raw WHERE takes precedence when populated', () {
      const filter = TableFilter(
        root: FilterGroup(
          conditions: [
            FilterCondition(
              column: 'age',
              op: FilterOp.greaterThan,
              values: ['18'],
            ),
          ],
        ),
        rawWhere: 'status = \'active\' AND total > 100',
      );
      expect(filter.toWherePreview(), 'status = \'active\' AND total > 100');
    });

    test('single condition formatting for various operators', () {
      const eq = FilterCondition(
        column: 'id',
        op: FilterOp.equals,
        values: ['42'],
      );
      expect(formatConditionPreview(eq), "id = '42'");

      const ne = FilterCondition(
        column: 'name',
        op: FilterOp.notEquals,
        values: ['Alice'],
      );
      expect(formatConditionPreview(ne), "name != 'Alice'");

      const isNull = FilterCondition(column: 'email', op: FilterOp.isNull);
      expect(formatConditionPreview(isNull), 'email IS NULL');

      const isNotNull = FilterCondition(
        column: 'phone',
        op: FilterOp.isNotNull,
      );
      expect(formatConditionPreview(isNotNull), 'phone IS NOT NULL');

      const between = FilterCondition(
        column: 'created_at',
        op: FilterOp.between,
        values: ['2026-01-01', '2026-12-31'],
      );
      expect(
        formatConditionPreview(between),
        "created_at BETWEEN '2026-01-01' AND '2026-12-31'",
      );

      const inList = FilterCondition(
        column: 'role',
        op: FilterOp.inList,
        values: ['admin', 'manager', 'guest'],
      );
      expect(
        formatConditionPreview(inList),
        "role IN ('admin', 'manager', 'guest')",
      );

      const like = FilterCondition(
        column: 'title',
        op: FilterOp.like,
        values: ['%test%'],
      );
      expect(formatConditionPreview(like), "title LIKE '%test%'");

      const ilike = FilterCondition(
        column: 'email',
        op: FilterOp.ilike,
        values: ['%@acme.org'],
      );
      expect(formatConditionPreview(ilike), "email ILIKE '%@acme.org'");
    });

    test('composite AND and OR groups round-trip', () {
      const groupAnd = FilterGroup(
        op: LogicalOp.and,
        conditions: [
          FilterCondition(
            column: 'active',
            op: FilterOp.equals,
            values: ['true'],
          ),
          FilterCondition(
            column: 'score',
            op: FilterOp.greaterThanOrEqual,
            values: ['90'],
          ),
        ],
      );
      expect(formatGroupPreview(groupAnd), "active = 'true' AND score >= '90'");

      const groupOr = FilterGroup(
        op: LogicalOp.or,
        conditions: [
          FilterCondition(
            column: 'role',
            op: FilterOp.equals,
            values: ['admin'],
          ),
          FilterCondition(
            column: 'role',
            op: FilterOp.equals,
            values: ['owner'],
          ),
        ],
      );
      expect(formatGroupPreview(groupOr), "role = 'admin' OR role = 'owner'");

      final nested = FilterGroup(
        op: LogicalOp.and,
        conditions: const [
          FilterCondition(
            column: 'deleted',
            op: FilterOp.equals,
            values: ['false'],
          ),
        ],
        groups: [groupOr],
      );
      expect(
        formatGroupPreview(nested),
        "deleted = 'false' AND (role = 'admin' OR role = 'owner')",
      );
    });
  });
}
