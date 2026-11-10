import 'package:flutter/painting.dart' show Axis;
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/editor/domain/editor_layout.dart';

EditorLayout three() => const EditorLayout().reconcile(
  tabIds: ['a', 'b', 'c'],
  requestedActive: 'c',
);

void main() {
  _groupCap();
  test('a tab dropped on another group joins it and is shown there', () {
    final moved = three().split(Axis.horizontal).moveTab('a', 1);
    expect(moved.groups.map((g) => g.tabIds), [
      ['b'],
      ['c', 'a'],
    ]);
    expect(moved.focused, 1);
    expect(moved.groups[1].activeId, 'a');
    expect(moved.groups[0].activeId, 'b');
  });

  test(
    'a tab dropped on a tab lands in front of it, also in its own group',
    () {
      final split = three().split(Axis.horizontal);
      expect(split.moveTab('a', 1, before: 'c').groups[1].tabIds, ['a', 'c']);
      expect(three().moveTab('c', 0, before: 'a').groups.single.tabIds, [
        'c',
        'a',
        'b',
      ]);
    },
  );

  test('moving the last tab out of a group removes the group', () {
    final moved = three().split(Axis.horizontal).moveTab('c', 0);
    expect(moved.groups.single.tabIds, ['a', 'b', 'c']);
    expect(moved.fractions, [1.0]);
    expect(moved.focused, 0);
  });

  test('moving an unknown tab or to a missing group changes nothing', () {
    final split = three().split(Axis.horizontal);
    expect(split.moveTab('zz', 0), split);
    expect(split.moveTab('a', 5), split);
    expect(split.moveTab('a', 0, before: 'a'), split);
  });

  test('new tabs join the focused group and become active', () {
    final l = three();
    expect(l.groups.single.tabIds, ['a', 'b', 'c']);
    expect(l.focusedGroup.activeId, 'c');
  });

  test('split moves the active tab to a new focused group', () {
    final l = three().split(Axis.horizontal);
    expect(l.groups.map((g) => g.tabIds), [
      ['a', 'b'],
      ['c'],
    ]);
    expect(l.focused, 1);
    expect(l.fractions, [0.5, 0.5]);
    expect(l.groups[0].activeId, 'b');
  });

  test('a lone tab cannot be split off, and the axis stays', () {
    final one = const EditorLayout().reconcile(tabIds: ['a']);
    expect(one.canSplit, isFalse);
    expect(one.split(Axis.horizontal), one);
    final two = three().split(Axis.horizontal);
    expect(two.split(Axis.vertical), two);
    final nested = two.focusGroup(0).split(Axis.horizontal);
    expect(nested.groups, hasLength(3));
    expect(nested.fractions, [0.25, 0.25, 0.5]);
  });

  test(
    'closing the last tab of a group removes it and gives its share away',
    () {
      final split = three().split(Axis.horizontal);
      final closed = split.reconcile(tabIds: ['a', 'b']);
      expect(closed.groups, hasLength(1));
      expect(closed.fractions, [1.0]);
      expect(closed.focused, 0);
    },
  );

  test('requesting a tab in another group focuses that group', () {
    final split = three().split(Axis.horizontal);
    final back = split.reconcile(tabIds: ['a', 'b', 'c'], requestedActive: 'a');
    expect(back.focused, 0);
    expect(back.groups[0].activeId, 'a');
  });

  test('moving the active tab to the next group wraps around', () {
    final split = three().split(Axis.horizontal);
    final moved = split.moveActive(1);
    expect(moved.groups.map((g) => g.tabIds), [
      ['a', 'b', 'c'],
    ]);
    final apart = three().split(Axis.horizontal).focusGroup(0).moveActive(1);
    expect(apart.groups[1].tabIds, ['c', 'b']);
    expect(apart.focused, 1);
    expect(apart.focusedGroup.activeId, 'b');
  });

  test('closing picks the neighbour in the group, else the next group', () {
    final split = three().split(Axis.horizontal);
    expect(split.successorOnClose('a'), 'b');
    expect(split.successorOnClose('b'), 'a');
    expect(split.successorOnClose('c'), 'b');
  });

  test('resizing keeps both panes above the minimum', () {
    final split = three().split(Axis.horizontal);
    final grown = split.resize(0, 0.2);
    expect(grown.fractions[0], closeTo(0.7, 1e-9));
    expect(grown.fractions.reduce((a, b) => a + b), closeTo(1, 1e-9));
    expect(split.resize(0, 5).fractions[1], closeTo(0.18, 1e-9));
    expect(split.resize(0, -5).fractions[0], closeTo(0.18, 1e-9));
    expect(split.resize(1, 0.1), split);
  });

  test('a layout survives JSON and new tab ids', () {
    final l = three().split(Axis.vertical).resize(0, 0.1);
    final back = EditorLayout.fromJson(l.toJson(['a', 'b', 'c']), [
      'x',
      'y',
      'z',
    ]);
    expect(back?.groups.map((g) => g.tabIds), [
      ['x', 'y'],
      ['z'],
    ]);
    expect(back?.axis, Axis.vertical);
    expect(back?.focused, 1);
    expect(back?.fractions[0], closeTo(0.6, 1e-9));
  });

  test('JSON that does not match the tabs is refused', () {
    final json = three().split(Axis.horizontal).toJson(['a', 'b', 'c']);
    expect(EditorLayout.fromJson(json, ['x', 'y']), isNull);
    expect(EditorLayout.fromJson(json, ['x', 'y', 'z', 'w']), isNull);
    expect(EditorLayout.fromJson('nope', ['x']), isNull);
    expect(
      EditorLayout.fromJson(<String, Object?>{
        'groups': <Object?>[],
        'fractions': <Object?>[],
      }, <String>[]),
      isNull,
    );
  });
}

void _groupCap() {
  test('at most four groups', () {
    var l = const EditorLayout().reconcile(
      tabIds: ['a', 'b', 'c', 'd', 'e', 'f'],
    );
    for (var i = 0; i < 6; i++) {
      l = l.focusGroup(0).split(Axis.horizontal);
    }
    expect(l.groups, hasLength(maxGroups));
    expect(l.fractions.reduce((a, b) => a + b), closeTo(1, 1e-9));
  });
}
