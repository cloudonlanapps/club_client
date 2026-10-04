import 'package:meta/meta.dart';

/// Complete Landing page data from server.
///
/// Loaded from `/static/pages/landing.json`.
@immutable
class LandingPageData {
  const LandingPageData({required this.hero, required this.nav});

  final LandingHeroData hero;
  final NavLabelsData nav;

  LandingPageData copyWith({LandingHeroData? hero, NavLabelsData? nav}) {
    return LandingPageData(hero: hero ?? this.hero, nav: nav ?? this.nav);
  }

  @override
  String toString() => 'LandingPageData(hero: $hero, nav: $nav)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandingPageData && other.hero == hero && other.nav == nav;
  }

  @override
  int get hashCode => hero.hashCode ^ nav.hashCode;
}

/// Hero section data for landing page.
@immutable
class LandingHeroData {
  const LandingHeroData({
    required this.learnMoreButton,
    required this.scrollIndicatorText,
    required this.carouselTexts,
    this.defaultBackgroundImage,
  });

  final String learnMoreButton;
  final String scrollIndicatorText;
  final List<String> carouselTexts;

  /// Default background image path for hero section when no highlight is
  /// active.
  /// Example: `/static/images/ring_background.jpg`
  final String? defaultBackgroundImage;

  LandingHeroData copyWith({
    String? learnMoreButton,
    String? scrollIndicatorText,
    List<String>? carouselTexts,
    String? Function()? defaultBackgroundImage,
  }) {
    return LandingHeroData(
      learnMoreButton: learnMoreButton ?? this.learnMoreButton,
      scrollIndicatorText: scrollIndicatorText ?? this.scrollIndicatorText,
      carouselTexts: carouselTexts ?? this.carouselTexts,
      defaultBackgroundImage: defaultBackgroundImage != null
          ? defaultBackgroundImage()
          : this.defaultBackgroundImage,
    );
  }

  @override
  String toString() =>
      'LandingHeroData(learnMoreButton: $learnMoreButton, '
      'scrollIndicatorText: $scrollIndicatorText, carouselTexts: '
      '$carouselTexts, defaultBackgroundImage: $defaultBackgroundImage)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandingHeroData &&
        other.learnMoreButton == learnMoreButton &&
        other.scrollIndicatorText == scrollIndicatorText &&
        _listEquals(other.carouselTexts, carouselTexts) &&
        other.defaultBackgroundImage == defaultBackgroundImage;
  }

  @override
  int get hashCode =>
      learnMoreButton.hashCode ^
      scrollIndicatorText.hashCode ^
      carouselTexts.hashCode ^
      defaultBackgroundImage.hashCode;
}

/// Navigation labels data.
@immutable
class NavLabelsData {
  const NavLabelsData({
    required this.home,
    required this.programs,
    required this.events,
    required this.oneOff,
    required this.coaches,
    required this.rinks,
    required this.aboutUs,
    required this.contactUs,
    required this.menu,
  });

  final String home;
  final String programs;
  final String events;
  final String oneOff;
  final String coaches;
  final String rinks;
  final String aboutUs;
  final String contactUs;
  final String menu;

  NavLabelsData copyWith({
    String? home,
    String? programs,
    String? events,
    String? oneOff,
    String? coaches,
    String? rinks,
    String? aboutUs,
    String? contactUs,
    String? menu,
  }) {
    return NavLabelsData(
      home: home ?? this.home,
      programs: programs ?? this.programs,
      events: events ?? this.events,
      oneOff: oneOff ?? this.oneOff,
      coaches: coaches ?? this.coaches,
      rinks: rinks ?? this.rinks,
      aboutUs: aboutUs ?? this.aboutUs,
      contactUs: contactUs ?? this.contactUs,
      menu: menu ?? this.menu,
    );
  }

  @override
  String toString() =>
      'NavLabelsData(home: $home, programs: $programs, events: $events, '
      'oneOff: $oneOff, coaches: $coaches, rinks: $rinks, aboutUs: $aboutUs, '
      'contactUs: $contactUs, menu: $menu)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavLabelsData &&
        other.home == home &&
        other.programs == programs &&
        other.events == events &&
        other.oneOff == oneOff &&
        other.coaches == coaches &&
        other.rinks == rinks &&
        other.aboutUs == aboutUs &&
        other.contactUs == contactUs &&
        other.menu == menu;
  }

  @override
  int get hashCode =>
      home.hashCode ^
      programs.hashCode ^
      events.hashCode ^
      oneOff.hashCode ^
      coaches.hashCode ^
      rinks.hashCode ^
      aboutUs.hashCode ^
      contactUs.hashCode ^
      menu.hashCode;
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
