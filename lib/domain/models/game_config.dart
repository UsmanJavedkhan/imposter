import 'enums.dart';

/// The settings chosen before a game starts.
///
/// Immutable, like everything else in the domain layer.
class GameConfig {
  /// Local (pass-and-play) or online.
  final GameMode mode;

  /// Display name of the chosen theme, e.g. "Animals".
  final String themeName;

  /// How many imposters to assign at the start.
  final int imposterCount;

  const GameConfig({
    required this.mode,
    required this.themeName,
    required this.imposterCount,
  });

  GameConfig copyWith({
    GameMode? mode,
    String? themeName,
    int? imposterCount,
  }) {
    return GameConfig(
      mode: mode ?? this.mode,
      themeName: themeName ?? this.themeName,
      imposterCount: imposterCount ?? this.imposterCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GameConfig &&
      other.mode == mode &&
      other.themeName == themeName &&
      other.imposterCount == imposterCount;

  @override
  int get hashCode => Object.hash(mode, themeName, imposterCount);

  @override
  String toString() =>
      'GameConfig(mode=$mode, theme=$themeName, imposters=$imposterCount)';
}
