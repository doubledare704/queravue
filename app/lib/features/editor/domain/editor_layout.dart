import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Axis;

const minGroupFraction = 0.18;
const maxGroups = 4;

@immutable
class EditorGroup {
  const EditorGroup({this.tabIds = const [], this.activeId});

  final List<String> tabIds;
  final String? activeId;

  EditorGroup copyWith({List<String>? tabIds, String? activeId}) =>
      EditorGroup(tabIds: tabIds ?? this.tabIds, activeId: activeId);

  @override
  bool operator ==(Object other) =>
      other is EditorGroup &&
      other.activeId == activeId &&
      listEquals(other.tabIds, tabIds);

  @override
  int get hashCode => Object.hash(activeId, Object.hashAll(tabIds));
}

/// How the tabs of one connection are split into side-by-side groups.
/// Groups are laid out along one [axis]; [fractions] are their shares.
@immutable
class EditorLayout {
  const EditorLayout({
    this.groups = const [EditorGroup()],
    this.focused = 0,
    this.axis = Axis.horizontal,
    this.fractions = const [1.0],
  });

  final List<EditorGroup> groups;
  final int focused;
  final Axis axis;
  final List<double> fractions;

  EditorGroup get focusedGroup => groups[focused];

  int groupOf(String tabId) =>
      groups.indexWhere((g) => g.tabIds.contains(tabId));

  List<String> get allTabIds => [for (final g in groups) ...g.tabIds];

  /// Brings the layout in line with the tabs that exist: closed tabs leave,
  /// new tabs join the focused group and become its active tab, and
  /// [requestedActive] focuses the group that holds it.
  EditorLayout reconcile({
    required List<String> tabIds,
    String? requestedActive,
  }) {
    final exists = tabIds.toSet();
    final known = allTabIds.toSet();
    final fresh = [
      for (final id in tabIds)
        if (!known.contains(id)) id,
    ];
    var groups = [
      for (final g in this.groups)
        () {
          final members = [
            for (final id in g.tabIds)
              if (exists.contains(id)) id,
          ];
          return g.copyWith(
            tabIds: members,
            activeId: members.contains(g.activeId) ? g.activeId : null,
          );
        }(),
    ];
    var focus = focused.clamp(0, groups.length - 1);
    if (fresh.isNotEmpty) {
      groups[focus] = groups[focus].copyWith(
        tabIds: [...groups[focus].tabIds, ...fresh],
        activeId: fresh.last,
      );
    }
    final fractions = List.of(this.fractions);
    for (var i = groups.length - 1; i >= 0 && groups.length > 1; i--) {
      if (groups[i].tabIds.isNotEmpty) continue;
      final share = fractions.removeAt(i);
      groups.removeAt(i);
      fractions[i == 0 ? 0 : i - 1] += share;
      if (focus > i || focus == groups.length) focus--;
    }
    focus = focus.clamp(0, groups.length - 1);
    groups = [
      for (final g in groups)
        g.activeId == null && g.tabIds.isNotEmpty
            ? g.copyWith(activeId: g.tabIds.last)
            : g,
    ];
    final target = requestedActive == null
        ? -1
        : groups.indexWhere((g) => g.tabIds.contains(requestedActive));
    if (target >= 0) {
      groups[target] = groups[target].copyWith(activeId: requestedActive);
      focus = target;
    }
    final next = EditorLayout(
      groups: groups,
      focused: focus,
      axis: axis,
      fractions: fractions,
    );
    return next == this ? this : next;
  }

  /// The tab to show after [tabId] closes: its neighbour in the group, else
  /// the active tab of the nearest other group.
  String? successorOnClose(String tabId) {
    final gi = groupOf(tabId);
    if (gi < 0) return null;
    final ids = groups[gi].tabIds;
    final at = ids.indexOf(tabId);
    if (ids.length > 1) return ids[at + 1 < ids.length ? at + 1 : at - 1];
    for (final offset in [1, -1]) {
      final other = gi + offset;
      if (other >= 0 && other < groups.length) return groups[other].activeId;
    }
    return null;
  }

  bool get canSplit =>
      focusedGroup.tabIds.length > 1 && groups.length < maxGroups;

  /// Moves the focused group's active tab into a new group after it. The
  /// first split picks the axis; later splits keep it.
  EditorLayout split(Axis along) {
    final group = focusedGroup;
    final moving = group.activeId;
    if (!canSplit || moving == null) return this;
    if (groups.length > 1 && along != axis) return this;
    final remaining = [
      for (final id in group.tabIds)
        if (id != moving) id,
    ];
    final share = fractions[focused] / 2;
    return EditorLayout(
      groups: [
        ...groups.take(focused),
        group.copyWith(tabIds: remaining, activeId: remaining.last),
        EditorGroup(tabIds: [moving], activeId: moving),
        ...groups.skip(focused + 1),
      ],
      focused: focused + 1,
      axis: along,
      fractions: [
        ...fractions.take(focused),
        share,
        share,
        ...fractions.skip(focused + 1),
      ],
    );
  }

  /// Moves the focused group's active tab into the group [delta] places away,
  /// wrapping around. The source group disappears when it becomes empty.
  EditorLayout moveActive(int delta) {
    final moving = focusedGroup.activeId;
    if (groups.length < 2 || moving == null) return this;
    final to = (focused + delta) % groups.length;
    final groups2 = [
      for (var i = 0; i < groups.length; i++)
        if (i == focused)
          groups[i].copyWith(
            tabIds: [
              for (final id in groups[i].tabIds)
                if (id != moving) id,
            ],
          )
        else if (i == to)
          groups[i].copyWith(
            tabIds: [...groups[i].tabIds, moving],
            activeId: moving,
          )
        else
          groups[i],
    ];
    return EditorLayout(
      groups: groups2,
      focused: to,
      axis: axis,
      fractions: fractions,
    ).reconcile(tabIds: allTabIds, requestedActive: moving);
  }

  /// Moves [tabId] into group [toGroup], in front of [before] or at the end,
  /// and shows it there. The source group disappears when it becomes empty.
  EditorLayout moveTab(String tabId, int toGroup, {String? before}) {
    if (groupOf(tabId) < 0 || before == tabId) return this;
    if (toGroup < 0 || toGroup >= groups.length) return this;
    final moved = [
      for (final g in groups)
        g.copyWith(
          tabIds: [
            for (final id in g.tabIds)
              if (id != tabId) id,
          ],
          activeId: g.activeId == tabId ? null : g.activeId,
        ),
    ];
    final target = moved[toGroup].tabIds;
    final found = before == null ? -1 : target.indexOf(before);
    final at = found < 0 ? target.length : found;
    moved[toGroup] = EditorGroup(
      tabIds: [...target.take(at), tabId, ...target.skip(at)],
      activeId: tabId,
    );
    return EditorLayout(
      groups: moved,
      focused: toGroup,
      axis: axis,
      fractions: fractions,
    ).reconcile(tabIds: allTabIds, requestedActive: tabId);
  }

  EditorLayout focusGroup(int index) => index < 0 || index >= groups.length
      ? this
      : EditorLayout(
          groups: groups,
          focused: index,
          axis: axis,
          fractions: fractions,
        );

  /// Moves the divider after group [index] by [delta] (a share of the whole),
  /// keeping both neighbours above the minimum size.
  EditorLayout resize(int index, double delta) {
    if (index < 0 || index >= groups.length - 1) return this;
    final pair = fractions[index] + fractions[index + 1];
    final least = math.min(minGroupFraction, pair / 3);
    final left = (fractions[index] + delta).clamp(least, pair - least);
    final next = List.of(fractions);
    next[index] = left;
    next[index + 1] = pair - left;
    return EditorLayout(
      groups: groups,
      focused: focused,
      axis: axis,
      fractions: next,
    );
  }

  /// Layout with tab ids replaced by their position in [order].
  Map<String, Object?> toJson(List<String> order) => {
    'axis': axis.name,
    'focused': focused,
    'fractions': fractions,
    'groups': [
      for (final g in groups)
        {
          'tabs': [for (final id in g.tabIds) order.indexOf(id)],
          'active': g.activeId == null ? null : order.indexOf(g.activeId!),
        },
    ],
  };

  /// Inverse of [toJson]; [ids] are the new tab ids by position. Null if the
  /// data does not describe a layout of exactly those tabs.
  static EditorLayout? fromJson(Object? json, List<String> ids) {
    if (json is! Map<String, Object?>) return null;
    final rawGroups = json['groups'];
    final rawFractions = json['fractions'];
    if (rawGroups is! List || rawFractions is! List) return null;
    if (rawGroups.isEmpty || rawGroups.length != rawFractions.length) {
      return null;
    }
    final seen = <int>{};
    final groups = <EditorGroup>[];
    for (final raw in rawGroups) {
      if (raw is! Map<String, Object?>) return null;
      final tabs = raw['tabs'];
      if (tabs is! List) return null;
      final members = <String>[];
      for (final t in tabs) {
        if (t is! int || t < 0 || t >= ids.length || !seen.add(t)) return null;
        members.add(ids[t]);
      }
      final active = raw['active'];
      groups.add(
        EditorGroup(
          tabIds: members,
          activeId: active is int && active >= 0 && active < ids.length
              ? ids[active]
              : null,
        ),
      );
    }
    if (seen.length != ids.length) return null;
    final fractions = [
      for (final f in rawFractions)
        if (f is num) f.toDouble(),
    ];
    if (fractions.length != groups.length || fractions.any((f) => f <= 0)) {
      return null;
    }
    final total = fractions.fold<double>(0, (a, b) => a + b);
    final focused = json['focused'];
    return EditorLayout(
      groups: groups,
      focused: focused is int ? focused.clamp(0, groups.length - 1) : 0,
      axis: json['axis'] == 'vertical' ? Axis.vertical : Axis.horizontal,
      fractions: [for (final f in fractions) f / total],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EditorLayout &&
      other.focused == focused &&
      other.axis == axis &&
      listEquals(other.groups, groups) &&
      listEquals(other.fractions, fractions);

  @override
  int get hashCode => Object.hash(
    focused,
    axis,
    Object.hashAll(groups),
    Object.hashAll(fractions),
  );
}
