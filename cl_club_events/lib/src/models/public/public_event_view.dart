import 'package:cl_remote_store/cl_remote_store.dart' show MediaUrlBuilder;
import 'package:club_sdk_2/club_sdk_2.dart';

import 'event_highlight.dart';
import 'highlight.dart';

/// One public event as the website renders it.
///
/// The old server sent an `EventWithAuxInfo`: event, marketing, venue and
/// labels in a single response. club_core has no such composite. A
/// `PublicEvent` carries its own venue, its coaches and a basic marketing
/// block for cards; the richer [EventMarketing] is a **second** fetch, from a
/// module that can be switched off entirely.
///
/// So `marketing` is nullable, and that is not an edge case to guard once at
/// the top — it is a state every event surface has to render: no fees table,
/// no facilities, no packages, no offers, no eligibility block. What survives
/// is the event itself, which is always there.
///
/// Media arrives as descriptors — what the file is, what to call it, which
/// previews it has — so a [MediaUrlBuilder] comes along to turn them into
/// URLs; the providers hold the API base and build these.
class PublicEventView {
  const PublicEventView({
    required this.event,
    required this.media,
    this.marketing,
  });

  final PublicEvent event;

  /// The extended marketing block, or null when the module is off or the
  /// event has none.
  final EventMarketing? marketing;

  final MediaUrlBuilder media;

  // ══════════════════════════════════════════════════════════════════════════
  // THE EVENT ITSELF
  // ══════════════════════════════════════════════════════════════════════════

  String get publicId => event.publicId;
  String get title => event.title;
  String get description => event.description;
  EventType get type => event.type;
  String get venueId => event.venueId;
  PublicVenue get venue => event.venue;
  List<PublicProfile> get coaches => event.coaches;
  String? get rrule => event.rrule;
  DateTime get startTimeUtc => event.startTimeUtc;
  DateTime get endTimeUtc => event.endTimeUtc;
  List<EventSession>? get sessions => event.sessions;
  bool get isFeatured => event.isFeatured;

  /// Whether every occurrence has finished. Server-computed.
  bool get isPast => event.isPast;

  bool get isActive => !isPast;

  /// The venue is part of the event now, so this is never empty and the
  /// null-venue branches the widgets carried are gone.
  String get venueDisplay => event.venue.name;

  /// The event's cover, or null when it has none.
  MediaRef? get cover => event.cover;

  /// The gallery in order of attachment.
  ///
  /// Routinely mixed: the camp gallery is twelve photos and four videos, and
  /// the selection trials carry a PDF. Read each item's type rather than
  /// assuming, and take its preview from [previewUriOf] rather than deriving
  /// one from the URL.
  List<MediaRef> get gallery => event.gallery;

  String? get imageUri => media(event.cover);

  /// The still to show for the cover where it cannot be rendered inline.
  String? get imagePreviewUri => media.preview(event.cover);

  List<String> get galleryUris =>
      event.gallery.map(media.call).whereType<String>().toList();

  /// Where [item]'s still preview lives, or null when it is its own preview.
  String? previewUriOf(MediaRef item) => media.preview(item);

  /// The URL for [item].
  String uriOf(MediaRef item) => media(item)!;

  // ══════════════════════════════════════════════════════════════════════════
  // THE BASIC MARKETING BLOCK — on the event, no second call
  // ══════════════════════════════════════════════════════════════════════════

  String? get stamp => event.marketing?.stamp;
  List<String>? get highlights => event.marketing?.highlights;
  List<String>? get includes => event.marketing?.includes;

  /// The line under the title on a card.
  ///
  /// The old model had a separate `tagline`, the single widest-used field of
  /// the four with no home in club_core. `shortDescription` is the nearest
  /// thing the server carries and serves the same purpose, so the two are
  /// folded together here rather than decided again at each of fifteen call
  /// sites.
  String? get tagline => event.marketing?.shortDescription;

  /// The long form. `description` is it; there is no second, longer field.
  String? get fullDescription => event.description;

  // ══════════════════════════════════════════════════════════════════════════
  // THE EXTENDED MARKETING BLOCK — a second fetch, and optional
  // ══════════════════════════════════════════════════════════════════════════

  String? get eligibility => marketing?.eligibilityText;
  String? get eligibilityNote => marketing?.eligibilityNote;
  bool get hasOpenSlots => marketing?.hasOpenSlots ?? true;
  String? get urgencyText => marketing?.urgencyText;
  String? get contactNumber => marketing?.contactNumber;
  List<Facility>? get facilities => marketing?.facilities;
  List<PackageOffer>? get packageOffers => marketing?.packageOffers;
  List<PromotionalOffer>? get offers => marketing?.offers;
  ClubMembership? get clubMembership => marketing?.clubMembership;
  DateTime? get registrationDeadline => marketing?.registrationDeadlineUtc;
  String? get duration => marketing?.durationText;
  String? get schedule => marketing?.scheduleText;

  /// The single headline fee.
  int? get fees => marketing?.fee;

  /// The fee table. `effectiveFees` already picks the structure over the
  /// single fee, so this is empty rather than null-vs-empty.
  List<FeeItem>? get feeStructure {
    final rows = marketing?.effectiveFees ?? const <FeeItem>[];
    return rows.isEmpty ? null : rows;
  }

  /// Whether the registration deadline has passed.
  ///
  /// A method on [EventMarketing] rather than a server-computed flag, and
  /// unknowable when the module is off — in which case nothing is closed,
  /// because nothing said it was.
  bool get isRegistrationClosed =>
      marketing?.isRegistrationClosed(DateTime.now().toUtc()) ?? false;

  /// The eligibility window as a phrase.
  ///
  /// The server modelled free text (`ageRange`) and now models the windows
  /// themselves — a gender and two dates of birth — so the phrase is derived
  /// rather than sent. Ages are computed against the event's start, not
  /// today: "for ages 8-12" means at the camp, not at the moment someone
  /// reads the page.
  String? get ageRange {
    final parts = <String>[];
    final after = event.dobOnOrAfterUtc;
    final before = event.dobOnOrBeforeUtc;

    // A later date of birth is a younger player, so the *oldest* eligible
    // player is the one born on or after `dobOnOrAfterUtc`.
    final youngest = before != null ? ageAtStart(before) : null;
    final oldest = after != null ? ageAtStart(after) : null;

    if (youngest != null && oldest != null) {
      parts.add('$youngest-$oldest');
    } else if (youngest != null) {
      parts.add('$youngest+');
    } else if (oldest != null) {
      parts.add('up to $oldest');
    }

    final gender = event.gender;
    if (gender != null && gender != Gender.preferNotToSay) {
      parts.add(gender.label.toLowerCase());
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// The age, at the event's start, of someone born on [dob].
  int ageAtStart(DateTime dob) {
    final start = event.startTimeUtc;
    var age = start.year - dob.year;
    final hadBirthday =
        start.month > dob.month ||
        (start.month == dob.month && start.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HIGHLIGHTS
  // ══════════════════════════════════════════════════════════════════════════

  Highlight toHighlight() => EventHighlight(this);
}
