/// Generates a club's Flutter web project from club_core's templates.
library;

export 'src/club_json.dart' show clubJsonFor;
export 'src/generator.dart'
    show
        GenerateOptions,
        brandFiles,
        generate,
        generatorRoot,
        mediaSlots,
        websiteFiles;
export 'src/pubspec_paths.dart' show absolutizePathDependencies;
export 'src/target.dart' show GeneratorException, Target;
export 'src/urls.dart' show checkUrl;
export 'src/web_colors.dart' show WebColors;
export 'src/web_files.dart'
    show WebNames, renderIcons, renderIndexHtml, renderManifest;
