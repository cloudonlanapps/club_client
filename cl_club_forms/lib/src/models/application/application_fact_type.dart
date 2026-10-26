/// The type of an application template's fact, as the template's JSON
/// names it: what the fact holds and how it prints. A clause's gap names
/// the type of fact it takes.
enum ApplicationFactType {
  /// A name, printed as typed: one text, or a text per language.
  name('name'),

  /// One day.
  date('date'),

  /// A first and a last day.
  dateRange('date_range'),

  /// A time of day, 24-hour.
  time('time'),

  /// A whole amount of money.
  amount('amount'),

  /// Choices of the library's list, printed joined with "and".
  choices('choices');

  const ApplicationFactType(this.jsonName);

  /// The key of a fact's type in the template's JSON.
  static const String typeKey = 'type';

  /// The type's name in the template's JSON.
  final String jsonName;

  /// The type named [json]; null when no type has that name.
  static ApplicationFactType? fromJson(Object? json) {
    for (final type in values) {
      if (type.jsonName == json) return type;
    }
    return null;
  }

  /// The type of each fact of [facts], a template's `facts` map, by the
  /// fact's name. A note (a key starting with `_`) and a fact of no known
  /// type are left out.
  static Map<String, ApplicationFactType> ofFacts(Object? facts) => {
    if (facts is Map)
      for (final entry in facts.entries)
        if (entry.key case final String name when !name.startsWith('_'))
          if (entry.value case final Map<Object?, Object?> fact)
            if (fromJson(fact[typeKey]) case final ApplicationFactType type)
              name: type,
  };
}
