import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'action_registry.dart';
import 'app_action.dart';

/// Runs the action bound to each chord. Conflicted chords are absent from
/// [ActionRegistry.bindings], so they fire nothing.
class ActionShortcuts extends ConsumerWidget {
  const ActionShortcuts({
    super.key,
    required this.registry,
    required this.enabledActionIds,
    required this.child,
  });

  final ActionRegistry registry;
  final ProviderListenable<Set<String>> enabledActionIds;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CallbackShortcuts(
    bindings: {
      for (final e in registry.bindings.entries)
        e.key.activator: () {
          if (ref.read(enabledActionIds).contains(e.value.id)) {
            e.value.run(context, ref);
          }
        },
    },
    child: child,
  );
}

bool get _nativeMenuAvailable =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// The macOS menu bar, one menu per action category. Items carry no key
/// equivalent: a native one would be handled before Flutter sees the key and
/// would take Enter and Escape away from the editors.
class ActionMenuBar extends ConsumerWidget {
  const ActionMenuBar({
    super.key,
    required this.registry,
    required this.enabledActionIds,
    required this.child,
  });

  final ActionRegistry registry;
  final ProviderListenable<Set<String>> enabledActionIds;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_nativeMenuAvailable) return child;
    final enabled = ref.watch(enabledActionIds);
    return PlatformMenuBar(
      menus: [
        const PlatformMenu(
          label: 'Queravue',
          menus: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.hideOtherApplications,
            ),
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ],
        ),
        for (final category in ActionCategory.values)
          if (registry.actions.any((a) => a.category == category && a.inMenu))
            PlatformMenu(
              label: category.label,
              menus: [
                for (final a in registry.actions)
                  if (a.category == category && a.inMenu)
                    PlatformMenuItem(
                      label: a.title,
                      onSelected: enabled.contains(a.id)
                          ? () => a.run(context, ref)
                          : null,
                    ),
              ],
            ),
      ],
      child: child,
    );
  }
}
