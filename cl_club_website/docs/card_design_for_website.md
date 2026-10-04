# Card Design for Website

## Card Components

| Card | File | Purpose |
|------|------|---------|
| ClubContactCard | `lib/src/widgets/club_contact_card.dart` | Address, phone, email with icons and Instagram QR code |
| CoachCard | `lib/src/widgets/coach_card.dart` | Coach profile with avatar, name, bio, achievements |
| VenueCard | `lib/src/widgets/venue_card.dart` | Venue name, address, primary badge (clickable) |
| ValueCard | `lib/src/widgets/value_card.dart` | Club values with icon, title, markdown description |
| EventCard | `lib/src/widgets/event_card.dart` | Unified card for all event types (programmes, camps, one-offs) |
| HeroEventCard | `lib/src/widgets/hero_event_card.dart` | Transparent event card for hero carousel overlay |
| EventHeroInfoCards | `lib/src/widgets/event_hero_info_cards.dart` | 4 info badges (Date, Timing, Eligibility, Venue) for detail pages |

## Card List Containers

| Container | File | Renders |
|-----------|------|---------|
| CoachesCardList | `lib/src/widgets/coaches_card_list.dart` | List of `CoachCard` |
| VenuesCardList | `lib/src/widgets/venues_card_list.dart` | List of `VenueCard` |
| EventCardList | `lib/src/widgets/event_card_list.dart` | List of `EventCard` |
| EventCardGrid | `lib/src/widgets/event_card_grid.dart` | Grid of `EventCard(compact: true)` for past events |

---

## ClubContactCard

```dart
const ClubContactCard({required ContactInfoLabels labels, required String whatsappLabel});
```

Displays club contact information from cl_remote_store's `contactInfoProvider` (server first, bundled fallback). Shows address, phone, email with icons, and Instagram QR code.

---

## CoachCard

```dart
const CoachCard({
  required PublicProfile coach,
  required bool isMobile,
});
```

| Parameter | Description |
|-----------|-------------|
| `coach` | Coach profile data (name, bio, avatar, achievements) |
| `isMobile` | Layout mode: vertical stack (mobile) or image-left (desktop) |

---

## VenueCard

```dart
const VenueCard({required Venue venue});
```

Clickable card displaying venue name, address, and primary badge. Navigates to `/public/rink/:id`.

---

## ValueCard

```dart
const ValueCard({
  required IconData icon,
  required String title,
  required String description,
});
```

Displays club values with circular icon, title, and markdown description. Used in grid layouts on The Club page.

---

## EventCard

Unified card widget for all event display needs.

```dart
const EventCard({
  required EventWithAuxInfo event,
  bool compact = false,
  bool showFeatures = true,
  bool showFees = true,
  bool showPrimaryButton = true,
  Map<String, String> cardLabels = const {},
});
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `compact` | `false` | Fixed-width grid layout with minimal content |
| `showFeatures` | `true` | Show features list (programmes only) |
| `showFees` | `true` | Show fees (camps/one-offs only, when not past) |
| `showPrimaryButton` | `true` | Show "Join Now" / "Register Now" button |

**Auto-detected from `event`:**

| Property | Source | Effect |
|----------|--------|--------|
| Event type | `event.type` | Programmes show schedule/duration; camps show dateRange/timings |
| Past state | `event.isPast` | Opacity, desaturation, "PAST" badge, "View Gallery" button |
| Stamp | `event.stamp` | Golden badge on image (camps/one-offs, not past) |
| Gallery | `event.galleryUris` | Gallery indicator (past events) |

**Layout:**
- Full mode: Responsive (vertical mobile, horizontal desktop)
- Compact mode: Fixed 340px width, image + title + date only

---

## HeroEventCard

Transparent event card for hero carousel overlay.

```dart
const HeroEventCard({
  required EventWithAuxInfo event,
  String buttonText = 'Learn More',
  VoidCallback? onButtonPressed,
  bool compact = false,
});
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `buttonText` | `'Learn More'` | Action button text |
| `onButtonPressed` | `null` | Button callback (hidden if null) |
| `compact` | `false` | Mobile sizing |

**Visual style:** Semi-transparent background, no image section, uses `InfoChip` for schedule/venue.

---

## EventHeroInfoCards

```dart
const EventHeroInfoCards({
  required EventWithAuxInfo event,
  required EventDetailHeroLabels labels,
});
```

Displays 4 info badges in event detail page hero section:
- **Date:** `dateRange` (camps/one-offs) or `effectiveSchedule` (programmes)
- **Timing:** `effectiveTimings`
- **Eligibility:** `ageRange` or `eligibility`
- **Venue:** Fetched venue name (clickable → `/public/rink/:id`)
