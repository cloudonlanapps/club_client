/// What the generator builds: the member app or the public website.
enum Target {
  app(
    templatePath: 'cl_club_app/example',
    descriptionSuffix: 'Official App',
  ),
  website(
    templatePath: 'cl_club_website/example',
    descriptionSuffix: 'Official Website',
  );

  const Target({required this.templatePath, required this.descriptionSuffix});

  /// The template's folder, relative to the club_core checkout.
  final String templatePath;

  /// Ends the page description: `<fullName> - <descriptionSuffix>`.
  final String descriptionSuffix;

  static Target parse(String name) =>
      Target.values.where((t) => t.name == name).firstOrNull ??
      (throw GeneratorException(
        'target must be one of ${Target.values.map((t) => t.name).join(', ')}, '
        'got "$name"',
      ));
}

/// A problem with the inputs. The generator stops with its message.
class GeneratorException implements Exception {
  const GeneratorException(this.message);

  final String message;

  @override
  String toString() => message;
}
