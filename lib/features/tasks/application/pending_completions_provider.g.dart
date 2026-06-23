// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_completions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingCompletionsHash() =>
    r'4b931aeaa41ae0a58c975c959fb52ef11ffb1705';

/// Gestiona las completaciones "diferidas": al tocar Hecho se marca la tarea
/// como pendiente (la pantalla la oculta) y se programa el commit real al
/// backend tras [kUndoWindow]. Mantiene el conjunto de `taskId` pendientes como
/// estado para que `todayViewModel` los filtre.
///
/// keepAlive: los temporizadores deben sobrevivir a reconstrucciones de la
/// pantalla Hoy. El flush por ciclo de vida (app en background) lo dispara
/// `app.dart` para no perder un completado si el proceso muere dentro de la
/// ventana.
///
/// Copied from [PendingCompletions].
@ProviderFor(PendingCompletions)
final pendingCompletionsProvider =
    NotifierProvider<PendingCompletions, Set<String>>.internal(
  PendingCompletions.new,
  name: r'pendingCompletionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingCompletionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingCompletions = Notifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
