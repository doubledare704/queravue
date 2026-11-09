import 'package:queravue/features/editor/application/layout_persistence.dart';

class NoLayoutPersistence extends LayoutPersistence {
  NoLayoutPersistence(super.ref);

  @override
  void start() {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> ensureLoaded(String tabId) async {}
}
