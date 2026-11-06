import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/table_view/application/pending_changes_controller.dart';
import 'package:queravue/features/table_view/domain/table_models.dart';

void main() {
  group('PendingChangesController & decoupling from page eviction', () {
    test('makePkKey produces deterministic sorted keys for composite PKs', () {
      final key1 = makePkKey({'order_id': 10, 'item_id': 2});
      final key2 = makePkKey({'item_id': 2, 'order_id': 10});
      expect(key1, equals(key2));
      expect(key1, 'item_id=2&order_id=10');
    });

    test(
      'cell updates are keyed by PK and survive simulated page eviction',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        const tableKey = 'conn1.public.orders';
        final controller = container.read(
          pendingChangesProvider(tableKey).notifier,
        );

        // User edits row with PK order_id = 500 (at page 1)
        controller.updateCell(
          pkValues: {'order_id': 500},
          column: 'status',
          newValue: 'shipped',
        );

        // Verify update is recorded
        var state = container.read(pendingChangesProvider(tableKey));
        final pkKey = makePkKey({'order_id': 500});
        expect(state.isUpdated(pkKey), isTrue);
        expect(state.getUpdatedValue(pkKey, 'status'), 'shipped');

        // User makes a second edit on the same row
        controller.updateCell(
          pkValues: {'order_id': 500},
          column: 'notes',
          newValue: 'Urgent delivery',
        );
        state = container.read(pendingChangesProvider(tableKey));
        expect(state.getUpdatedValue(pkKey, 'status'), 'shipped');
        expect(state.getUpdatedValue(pkKey, 'notes'), 'Urgent delivery');

        // --- SIMULATED PAGE EVICTION ---
        // User scrolls to row 900,000. In memory, local page buffer for row 500 is dropped/evicted.
        // Re-querying pending changes provider:
        final persistedState = container.read(pendingChangesProvider(tableKey));
        expect(
          persistedState.isUpdated(pkKey),
          isTrue,
          reason: 'Pending changes must not be lost when pages are evicted',
        );
        expect(persistedState.getUpdatedValue(pkKey, 'status'), 'shipped');
        expect(
          persistedState.getUpdatedValue(pkKey, 'notes'),
          'Urgent delivery',
        );

        // When user deletes another row with composite PK
        controller.deleteRow({'order_id': 600, 'item_id': 1});
        final compPkKey = makePkKey({'order_id': 600, 'item_id': 1});
        expect(
          container.read(pendingChangesProvider(tableKey)).isDeleted(compPkKey),
          isTrue,
        );

        // User adds a new row
        final tempId = controller.addRow({'status': 'pending', 'total': 150.0});
        expect(
          container
              .read(pendingChangesProvider(tableKey))
              .inserts
              .containsKey(tempId),
          isTrue,
        );

        // Export to RowChanges for ApplyChanges
        final changes = controller.toRowChanges();
        expect(changes.length, equals(3));
        expect(changes.any((c) => c.type == RowChangeType.insert), isTrue);
        expect(
          changes.any(
            (c) => c.type == RowChangeType.update && c.keys['order_id'] == 500,
          ),
          isTrue,
        );
        expect(
          changes.any(
            (c) => c.type == RowChangeType.delete && c.keys['order_id'] == 600,
          ),
          isTrue,
        );

        // Discard clears all
        controller.discard();
        expect(
          container.read(pendingChangesProvider(tableKey)).isEmpty,
          isTrue,
        );
      },
    );
  });
}
