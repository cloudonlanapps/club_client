
## EVent Details Camp / One Off 
```
    ┌─────────────────────────────────────────────────┐
    │         Camp Detail Content (Column)            │
    ├─────────────────────────────────────────────────┤
    │                                                 │
    │  ┌──────────────────────────────────────────┐   │
    │  │ 1. EventDescriptionSection               │   │
    │  │    (fullDescription / description)       │   │
    │  └──────────────────────────────────────────┘   │
    │          if description is non-empty            │
    │                                                 │
    │  ┌──────────────────────────────────────────┐   │
    │  │ 2. EventHeroInfoCards                    │   │
    │  │    (date, timing, venue)                 │   │
    │  └──────────────────────────────────────────┘   │
    │          always                                 │
    │                                                 │
    │  ┌──────────────────────────────────────────┐   │
    │  │ 3. EligibilitySection                    │   │
    │  │    (age range / eligibility + note)      │   │
    │  └──────────────────────────────────────────┘   │
    │          if hasEligibility && isActive          │
    │                                                 │
    │  ┌──────────────────────────────────────────┐   │
    │  │ 4. EventContentSection                   │   │
    │  │  ┌────────────────┐  ┌───────────────┐   │   │
    │  │  │ HighlightsCard │  │  CoachCard /  │   │   │
    │  │  │ (what's        │  │  "Coaches to  │   │   │
    │  │  │  included)     │  │   be          │   │   │
    │  │  │                │  │   announced"  │   │   │
    │  │  └────────────────┘  └───────────────┘   │   │
    │  └──────────────────────────────────────────┘   │
    │          always (highlights if available)       │
    │                                                 │
    │  ┌──────────────────────────────────────────┐   │
    │  │ 5. EventFeesSection                      │   │
    │  │    (simple fees line)                    │   │
    │  └──────────────────────────────────────────┘   │
    │          if hasFees && isActive                 │
    │                                                 │
    │  ┌──────────────────────────────────────────┐   │
    │  │ 6. EventGallerySection                   │   │
    │  │    (photo gallery grid)                  │   │
    │  └──────────────────────────────────────────┘   │
    │          if hasGallery                          │
    │                                                 │
    └─────────────────────────────────────────────────┘
  ```

  ## Training Sessions

  ┌─────────────────────────────────────────────────┐
  │       Program Detail Content (Column)            │
  ├─────────────────────────────────────────────────┤
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 1. EventDescriptionSection               │   │
  │  │    (fullDescription / description)       │   │
  │  └──────────────────────────────────────────┘   │
  │          if description is non-empty             │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 2. EventHeroInfoCards                    │   │
  │  │    (schedule, timing, venue)             │   │
  │  └──────────────────────────────────────────┘   │
  │          always                                  │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 3. BatchTimingsSection                   │   │
  │  │    (per-batch schedule table)            │   │
  │  │    e.g. Off-Ice: 6:00-6:45 AM           │   │
  │  │         On-Ice:  6:45-7:45 AM           │   │
  │  └──────────────────────────────────────────┘   │
  │          if hasBatches                           │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 4. FacilitiesSection                     │   │
  │  │    (rink/facility cards)                 │   │
  │  └──────────────────────────────────────────┘   │
  │          if hasFacilities                        │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 5. FeeStructureSection                   │   │
  │  │    (table + total row)                   │   │
  │  └──────────────────────────────────────────┘   │
  │          if hasFeeStructure                      │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 6. PackageOffersSection                  │   │
  │  │    (package deal cards)                  │   │
  │  └──────────────────────────────────────────┘   │
  │          if hasPackageOffers                      │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 7. OffersSection                         │   │
  │  │    (promotional offers)                  │   │
  │  └──────────────────────────────────────────┘   │
  │          if hasOffers                            │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 8. MembershipBenefitsSection             │   │
  │  │    (club membership perks)               │   │
  │  └──────────────────────────────────────────┘   │
  │          if hasMembership                        │
  │                                                  │
  │  ┌──────────────────────────────────────────┐   │
  │  │ 9. EventGallerySection                   │   │
  │  │    (photo gallery grid)                  │   │
  │  └──────────────────────────────────────────┘   │
  │          if hasGallery                           │
  │                                                  │
  └─────────────────────────────────────────────────┘