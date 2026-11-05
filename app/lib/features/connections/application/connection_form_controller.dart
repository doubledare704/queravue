import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/connections_repository.dart';
import '../domain/cancellation.dart';
import '../domain/models.dart';
import 'connections_controller.dart';

/// How the connection dialog was opened.
@immutable
class ConnectionFormArgs {
  /// Opens a form for a new connection, an edit, or a duplicate of [initial].
  /// Instances compare by identity: each dialog creates its own.
  const ConnectionFormArgs({
    required this.engines,
    this.initial,
    this.duplicate = false,
  });

  final List<EngineSpec> engines;
  final ConnectionProfile? initial;
  final bool duplicate;

  bool get isEdit => initial != null && initial!.isSaved && !duplicate;
}

/// State of the connection-test row in the dialog.
sealed class FormTestState {
  const FormTestState();
}

final class FormTestIdle extends FormTestState {
  const FormTestIdle();
}

final class FormTesting extends FormTestState {
  const FormTesting();
}

final class FormTested extends FormTestState {
  const FormTested(this.result);

  final TestResult result;
}

@immutable
class ConnectionFormState {
  const ConnectionFormState({
    required this.engine,
    required this.name,
    required this.folder,
    required this.color,
    required this.production,
    required this.values,
    this.password = '',
    this.passwordDirty = false,
    this.hasStoredPassword = false,
    this.clearStoredPassword = false,
    this.test = const FormTestIdle(),
    this.saving = false,
    this.error,
    this.revision = 0,
  });

  final EngineSpec engine;
  final String name;
  final String folder;
  final ColorTag color;
  final bool production;

  /// Param values keyed by field key.
  final Map<String, String> values;

  /// Typed password; only sent when [passwordDirty].
  final String password;
  final bool passwordDirty;

  /// The saved connection already has a keychain password.
  final bool hasStoredPassword;

  /// The user chose to remove the stored password.
  final bool clearStoredPassword;
  final FormTestState test;
  final bool saving;

  /// Validation or save error to show.
  final String? error;

  /// Bumped when values change from outside the text fields (engine switch,
  /// URI import), so the view can resync its controllers.
  final int revision;

  ConnectionFormState copyWith({
    EngineSpec? engine,
    String? name,
    String? folder,
    ColorTag? color,
    bool? production,
    Map<String, String>? values,
    String? password,
    bool? passwordDirty,
    bool? hasStoredPassword,
    bool? clearStoredPassword,
    FormTestState? test,
    bool? saving,
    String? Function()? error,
    int? revision,
  }) => ConnectionFormState(
    engine: engine ?? this.engine,
    name: name ?? this.name,
    folder: folder ?? this.folder,
    color: color ?? this.color,
    production: production ?? this.production,
    values: values ?? this.values,
    password: password ?? this.password,
    passwordDirty: passwordDirty ?? this.passwordDirty,
    hasStoredPassword: hasStoredPassword ?? this.hasStoredPassword,
    clearStoredPassword: clearStoredPassword ?? this.clearStoredPassword,
    test: test ?? this.test,
    saving: saving ?? this.saving,
    error: error != null ? error() : this.error,
    revision: revision ?? this.revision,
  );
}

/// All logic behind the new/edit connection dialog.
class ConnectionFormController extends Notifier<ConnectionFormState> {
  ConnectionFormController(this.args);

  final ConnectionFormArgs args;
  CancellationToken? _testToken;

  ConnectionsRepository get _repo => ref.read(connectionsRepositoryProvider);

  @override
  ConnectionFormState build() {
    ref.onDispose(() => _testToken?.cancel());
    final initial = args.initial;
    final engine = initial == null
        ? args.engines.first
        : args.engines.firstWhere(
            (e) => e.id == initial.engineId,
            orElse: () => args.engines.first,
          );
    if (initial == null) {
      return ConnectionFormState(
        engine: engine,
        name: '',
        folder: '',
        color: ColorTag.none,
        production: false,
        values: engine.defaults,
      );
    }
    return ConnectionFormState(
      engine: engine,
      name: args.duplicate ? '${initial.name} copy' : initial.name,
      folder: initial.folder,
      color: initial.color,
      production: args.duplicate ? false : initial.production,
      values: {...engine.defaults, ...initial.params},
      hasStoredPassword: args.isEdit && initial.hasPassword,
    );
  }

  /// Switches engine. Keeps values for fields both engines share (host,
  /// user...) only when they differ from the old engine's defaults.
  void selectEngine(String id) {
    final next = args.engines.firstWhere((e) => e.id == id);
    if (next.id == state.engine.id) return;
    final old = state.engine.defaults;
    final values = next.defaults;
    for (final f in next.paramFields) {
      final v = state.values[f.key];
      if (v != null && v.isNotEmpty && v != old[f.key]) values[f.key] = v;
    }
    state = state.copyWith(
      engine: next,
      values: values,
      test: const FormTestIdle(),
      error: () => null,
      revision: state.revision + 1,
    );
  }

  void setName(String v) => state = state.copyWith(name: v);

  void setFolder(String v) => state = state.copyWith(folder: v);

  void setColor(ColorTag v) => state = state.copyWith(color: v);

  void setProduction(bool v) => state = state.copyWith(production: v);

  void setField(String key, String value) => state = state.copyWith(
    values: {...state.values, key: value},
    test: const FormTestIdle(),
  );

  void setPassword(String v) => state = state.copyWith(
    password: v,
    passwordDirty: true,
    clearStoredPassword: false,
    test: const FormTestIdle(),
  );

  /// Marks the stored password for removal on save.
  void clearStoredPassword() => state = state.copyWith(
    clearStoredPassword: true,
    password: '',
    passwordDirty: true,
    test: const FormTestIdle(),
  );

  /// Fills fields from a pasted URI or DSN.
  Future<void> applyUri(String uri) async {
    if (uri.trim().isEmpty) return;
    try {
      final parsed = await _repo.parseUri(state.engine.id, uri.trim());
      state = state.copyWith(
        values: {...state.engine.defaults, ...parsed.params},
        password: parsed.password ?? state.password,
        passwordDirty: parsed.password != null || state.passwordDirty,
        test: const FormTestIdle(),
        error: () => null,
        revision: state.revision + 1,
      );
    } on ConnectionsException catch (e) {
      state = state.copyWith(error: () => "Couldn't parse URI: ${e.message}");
    }
  }

  /// The profile the form currently describes.
  ConnectionProfile get draft => ConnectionProfile(
    id: args.isEdit ? args.initial!.id : '',
    name: state.name.trim().isEmpty ? defaultName : state.name.trim(),
    engineId: state.engine.id,
    params: {
      for (final f in state.engine.paramFields)
        if ((state.values[f.key] ?? '').trim().isNotEmpty)
          f.key: state.values[f.key]!.trim(),
    },
    folder: state.folder.trim(),
    color: state.color,
    production: state.production,
  );

  /// `<Engine> @ host:port/db` (SQLite: the file name), built only from the
  /// form's own fields, never from a test result.
  String get defaultName {
    final v = state.values;
    String f(String k) => (v[k] ?? '').trim();
    final path = f('path');
    if (path.isNotEmpty) {
      return path.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty).last;
    }
    final host = f('host');
    if (host.isEmpty) return state.engine.displayName;
    final port = f('port');
    final db = f('database');
    return '${state.engine.displayName} @ $host'
        '${port.isEmpty ? '' : ':$port'}${db.isEmpty ? '' : '/$db'}';
  }

  /// Validates required fields. Returns an error message or null.
  String? validate({bool forSave = true}) {
    for (final f in state.engine.paramFields) {
      if (f.required && (state.values[f.key] ?? '').trim().isEmpty) {
        return '${f.label} is required';
      }
    }
    return null;
  }

  /// Tests the current settings. For edits and duplicates, an untouched
  /// password falls back to the one stored for the original connection.
  Future<void> test() async {
    final invalid = validate(forSave: false);
    if (invalid != null) {
      state = state.copyWith(error: () => invalid);
      return;
    }
    _testToken?.cancel();
    final token = _testToken = CancellationToken();
    state = state.copyWith(test: const FormTesting(), error: () => null);
    TestResult result;
    try {
      result = await _repo.test(
        id: args.initial?.isSaved == true ? args.initial!.id : null,
        draft: draft,
        password: state.passwordDirty ? state.password : null,
        cancel: token,
      );
    } on OperationCancelled {
      return;
    } on ConnectionsException catch (e) {
      result = TestFailed(ConnectionErrorKind.unknown, e.message);
    }
    if (!ref.mounted || token.isCancelled) return;
    state = state.copyWith(test: FormTested(result));
  }

  /// Abandons a running test.
  void cancelTest() {
    _testToken?.cancel();
    _testToken = null;
    state = state.copyWith(test: const FormTestIdle());
  }

  /// Saves and returns the saved profile, or null if validation or the save
  /// failed (see [ConnectionFormState.error]).
  Future<ConnectionProfile?> save() async {
    final invalid = validate();
    if (invalid != null) {
      state = state.copyWith(error: () => invalid);
      return null;
    }
    state = state.copyWith(saving: true, error: () => null);
    try {
      final pw = state.passwordDirty && state.password.isNotEmpty
          ? state.password
          : null;
      final saved = await ref
          .read(connectionsControllerProvider.notifier)
          .save(
            draft,
            password: pw,
            clearPassword: args.isEdit && state.clearStoredPassword,
          );
      if (ref.mounted) state = state.copyWith(saving: false);
      return saved;
    } on ConnectionsException catch (e) {
      if (ref.mounted) {
        state = state.copyWith(saving: false, error: () => e.message);
      }
      return null;
    }
  }
}

final connectionFormProvider = NotifierProvider.autoDispose
    .family<ConnectionFormController, ConnectionFormState, ConnectionFormArgs>(
      ConnectionFormController.new,
    );
