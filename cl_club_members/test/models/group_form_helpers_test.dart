import 'package:cl_club_forms/cl_club_forms.dart'
    show
        AgeEligibilityFormValues,
        FormAge,
        GroupFormFields,
        GroupGender,
        GroupMode;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_members/src/models/group_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// What one group write carried.
class _Sent {
  _Sent({
    required this.minAge,
    required this.maxAge,
    required this.strictAge,
    required this.gender,
    required this.semiAuto,
  });
  final Age? minAge;
  final Age? maxAge;
  final bool? strictAge;
  final Gender? gender;
  final bool? semiAuto;
}

/// Records the create and update calls the adapter sends.
class _RecordingNotifier extends ClGroupsMasterNotifier {
  final Group answer = Group(
    id: 1,
    name: 'Juniors',
    kind: GroupKind.semiAuto,
    createdAtUtc: DateTime.utc(2025),
  );
  final List<_Sent> created = [];
  final List<_Sent> updated = [];

  /// Whether the last update passed a getter for each bound (so it clears).
  bool updateSentBothAgeGetters = false;

  @override
  Future<Group> createGroup({
    required String name,
    String? description,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    Gender? gender,
    bool? semiAuto,
  }) async {
    created.add(
      _Sent(
        minAge: minAge,
        maxAge: maxAge,
        strictAge: strictAge,
        gender: gender,
        semiAuto: semiAuto,
      ),
    );
    return answer;
  }

  @override
  Future<Group> updateGroup(
    int id, {
    String? name,
    String? Function()? description,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    Gender? Function()? gender,
    bool? semiAuto,
  }) async {
    updateSentBothAgeGetters = minAge != null && maxAge != null;
    updated.add(
      _Sent(
        minAge: minAge?.call(),
        maxAge: maxAge?.call(),
        strictAge: strictAge,
        gender: gender?.call(),
        semiAuto: semiAuto,
      ),
    );
    return answer;
  }
}

Map<String, dynamic> _form({
  GroupMode mode = GroupMode.semiAuto,
  String minYears = '',
  String maxYears = '',
  bool strict = false,
  GroupGender? gender,
}) => {
  GroupFormFields.nameId: 'Juniors',
  GroupFormFields.descriptionId: '',
  GroupFormFields.modeId: mode,
  GroupFormFields.genderId: gender,
  ...AgeEligibilityFormValues.initial(strictAge: strict),
  AgeEligibilityFormFields.minAgeYearsId: minYears,
  AgeEligibilityFormFields.maxAgeYearsId: maxYears,
};

void main() {
  group('buildGroupFormInitialValues', () {
    test('null group → manual mode, empty fields', () {
      final values = buildGroupFormInitialValues(null);
      expect(values[GroupFormFields.modeId], GroupMode.manual);
      expect(values[GroupFormFields.nameId], '');
      expect(values[GroupFormFields.addMeId], false);
    });

    // Since club_client#33 the form takes the age band; the dates the server
    // reports are read-only and never seed it.
    test('auto group populates fields and maps kind + gender', () {
      final after = DateTime.utc(2010);
      final before = DateTime.utc(2016, 12, 31);
      final group = Group(
        id: 1,
        name: 'U12 Boys',
        kind: GroupKind.auto,
        description: 'Under 12',
        minAge: const Age(years: 9),
        maxAge: const Age(years: 12, months: 6),
        strictAge: true,
        dobOnOrAfterUtc: after,
        dobOnOrBeforeUtc: before,
        gender: Gender.male,
        createdAtUtc: DateTime.utc(2025),
      );

      final values = buildGroupFormInitialValues(group);

      expect(values[GroupFormFields.nameId], 'U12 Boys');
      expect(values[GroupFormFields.descriptionId], 'Under 12');
      expect(values[GroupFormFields.modeId], GroupMode.auto);
      expect(AgeEligibilityFormValues.minAge(values), const FormAge(years: 9));
      expect(
        AgeEligibilityFormValues.maxAge(values),
        const FormAge(years: 12, months: 6),
      );
      expect(AgeEligibilityFormValues.strictAge(values), isTrue);
      expect(values.values.whereType<DateTime>(), isEmpty);
      expect(values[GroupFormFields.genderId], GroupGender.male);
    });

    test('semi-auto group maps to GroupMode.semiAuto', () {
      final group = Group(
        id: 1,
        name: 'Semi',
        kind: GroupKind.semiAuto,
        dobOnOrAfterUtc: DateTime.utc(2010),
        createdAtUtc: DateTime.utc(2025),
      );

      final values = buildGroupFormInitialValues(group);
      expect(values[GroupFormFields.modeId], GroupMode.semiAuto);
    });

    test('manual group maps to GroupMode.manual with null criteria', () {
      final group = Group(
        id: 1,
        name: 'Manual Group',
        kind: GroupKind.manual,
        createdAtUtc: DateTime.utc(2025),
      );

      final values = buildGroupFormInitialValues(group);

      expect(values[GroupFormFields.modeId], GroupMode.manual);
      expect(values[GroupFormFields.descriptionId], '');
      expect(AgeEligibilityFormValues.minAge(values), isNull);
      expect(AgeEligibilityFormValues.maxAge(values), isNull);
      expect(AgeEligibilityFormValues.strictAge(values), isFalse);
      expect(values[GroupFormFields.genderId], isNull);
    });
  });

  group('Issue 33: GroupFormSubmit sends the age band', () {
    test('Issue 33: create sends minAge, maxAge and strictAge', () async {
      final notifier = _RecordingNotifier();
      await GroupFormSubmit.create(
        values: _form(minYears: '5', maxYears: '18', strict: true),
        notifier: notifier,
      );

      final sent = notifier.created.single;
      expect(sent.minAge, const Age(years: 5));
      expect(sent.maxAge, const Age(years: 18));
      expect(sent.strictAge, isTrue);
      expect(sent.semiAuto, isTrue);
    });

    test(
      'Issue 33: create with one age leaves the other bound unset',
      () async {
        final notifier = _RecordingNotifier();
        await GroupFormSubmit.create(
          values: _form(mode: GroupMode.auto, maxYears: '12'),
          notifier: notifier,
        );

        final sent = notifier.created.single;
        expect(sent.minAge, isNull);
        expect(sent.maxAge, const Age(years: 12));
        expect(sent.strictAge, isFalse);
        expect(sent.semiAuto, isFalse);
      },
    );

    test('Issue 33: updateEligibility sends minAge, maxAge and '
        'strictAge', () async {
      final notifier = _RecordingNotifier();
      await GroupFormSubmit.updateEligibility(
        values: _form(
          minYears: '5',
          maxYears: '18',
          strict: true,
          gender: GroupGender.female,
        ),
        groupId: 1,
        notifier: notifier,
      );

      final sent = notifier.updated.single;
      expect(sent.minAge, const Age(years: 5));
      expect(sent.maxAge, const Age(years: 18));
      expect(sent.strictAge, isTrue);
      expect(sent.gender, Gender.female);
    });

    test('Issue 33: an emptied age clears that bound', () async {
      final notifier = _RecordingNotifier();
      await GroupFormSubmit.updateEligibility(
        values: _form(maxYears: '18'),
        groupId: 1,
        notifier: notifier,
      );

      expect(notifier.updateSentBothAgeGetters, isTrue);
      expect(notifier.updated.single.minAge, isNull);
      expect(notifier.updated.single.maxAge, const Age(years: 18));
    });

    test('Issue 33: a manual group clears the band whatever the hidden '
        'inputs hold', () async {
      final notifier = _RecordingNotifier();
      await GroupFormSubmit.updateEligibility(
        values: _form(
          mode: GroupMode.manual,
          minYears: '5',
          maxYears: '18',
          strict: true,
        ),
        groupId: 1,
        notifier: notifier,
      );

      final sent = notifier.updated.single;
      expect(notifier.updateSentBothAgeGetters, isTrue);
      expect(sent.minAge, isNull);
      expect(sent.maxAge, isNull);
      expect(sent.strictAge, isFalse);
      expect(sent.semiAuto, isNull);
    });
  });

  group('Issue 55: what a refused write says to the group forms', () {
    ServerException refusal(String code, {Map<String, dynamic>? details}) =>
        ServerException(
          statusCode: 422,
          code: code,
          message: 'refused',
          details: details,
        );

    test('Issue 55: a switch to auto refused because the group has members '
        'is shown on the mode', () {
      final shown = GroupFormSubmit.eligibilityRefusal(
        refusal(SdkErrorCode.membersExist),
      );

      expect(shown!.fieldErrors, {
        GroupFormFields.modeId: GroupFormSubmit.membersExistMessage,
      });
      expect(shown.formError, isNull);
    });

    test('Issue 55: criteria that leave members out are shown inline, with '
        'their names', () {
      final shown = GroupFormSubmit.eligibilityRefusal(
        refusal(
          SdkErrorCode.membersIneligible,
          details: {
            'membernames': ['asha', 'ravi'],
          },
        ),
      );

      expect(shown!.fieldErrors, isEmpty);
      expect(
        shown.formError,
        "These members don't meet the new criteria: asha, ravi. "
        'Remove or update them, then retry.',
      );
    });

    test('Issue 55: an age band the server refuses is shown inline on both '
        'forms', () {
      final error = refusal(SdkErrorCode.invalidState);

      expect(
        GroupFormSubmit.createRefusal(error)!.formError,
        GroupFormSubmit.invertedBandMessage,
      );
      expect(
        GroupFormSubmit.eligibilityRefusal(error)!.formError,
        GroupFormSubmit.invertedBandMessage,
      );
    });

    test('Issue 55: any other failure names nothing on the form', () {
      expect(GroupFormSubmit.createRefusal(refusal('INTERNAL')), isNull);
      expect(GroupFormSubmit.createRefusal(StateError('x')), isNull);
      expect(GroupFormSubmit.eligibilityRefusal(refusal('INTERNAL')), isNull);
      expect(GroupFormSubmit.eligibilityRefusal(StateError('x')), isNull);
    });

    test('Issue 55: the create defaults carry every key the form holds, so '
        'a fresh form is not dirty', () {
      final values = buildGroupFormInitialValues(null);

      expect(values.containsKey(GroupFormFields.genderId), isTrue);
      expect(values[GroupFormFields.genderId], isNull);
    });
  });
}
