import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

/// Made-up data the forms are mounted with: no club, person or place here
/// exists.
abstract final class DemoSamples {
  /// The day the demo was opened, read once so a rebuilt form keeps the
  /// values it was first given.
  static final DateTime today = dayOf(DateTime.now());

  /// Days from [today] to the samples' first date.
  static const int soonDays = 7;

  /// Days from [today] to the samples' later date.
  static const int laterDays = 30;

  /// Days a sample credit package still runs.
  static const int creditDays = 45;

  /// Hour the sample sessions start at.
  static const int startHour = 18;

  /// Length of the sample sessions.
  static const int durationMinutes = 120;

  /// Training days of the sample camp.
  static const int campTrainingDays = 5;

  /// Credits left in the sample package.
  static const int creditBalance = 6;

  /// Id of the venue the samples are held at.
  static const int venueId = 1;

  /// A username the fake availability check reports as taken starts so.
  static const String takenPrefix = 'taken';

  /// The country calling code of the club in the samples. The sample
  /// phones carry their own: they are numbers set aside for made-up use.
  static const String countryCode = '91';

  /// The username of the member in the samples.
  static const String username = 'sam.sample';

  /// [moment] without its time.
  static DateTime dayOf(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  /// The day [days] after [today].
  static DateTime inDays(int days) =>
      DateTime(today.year, today.month, today.day + days);

  /// When the sample sessions start.
  static const ShadTimeOfDay startTime = ShadTimeOfDay(
    hour: startHour,
    minute: 0,
    second: 0,
  );

  /// The venues a form may choose from.
  static const List<EventVenueOption> venues = [
    EventVenueOption(id: venueId, name: 'Main Hall'),
    EventVenueOption(id: 2, name: 'Practice Room'),
    EventVenueOption(id: 3, name: 'Outdoor Court'),
  ];

  /// A split of a session of [durationMinutes] starting at [startTime].
  static const List<SessionInput> sessions = [
    SessionInput(name: 'Warm-up', startTime: '18:00', endTime: '18:30'),
    SessionInput(name: 'Drills', startTime: '18:30', endTime: '20:00'),
  ];

  /// The organizer of the sample event.
  static const EventStaffMember organizer = EventStaffMember(
    username: 'olive.organizer',
    displayName: 'Olive Organizer',
  );

  /// The coaches of the sample event.
  static const List<EventStaffMember> coaches = [
    EventStaffMember(username: 'casey.coach', displayName: 'Casey Coach'),
    EventStaffMember(username: 'toni.trainer', displayName: 'Toni Trainer'),
  ];

  /// The members the fake pickers offer.
  static const List<EventStaffMember> pickable = [
    EventStaffMember(username: 'pat.picked', displayName: 'Pat Picked'),
    EventStaffMember(username: 'drew.demo', displayName: 'Drew Demo'),
    EventStaffMember(username: 'alex.added', displayName: 'Alex Added'),
  ];

  /// The programmes credit may be granted for.
  static const List<CreditProgrammeOption> programmes = [
    CreditProgrammeOption(id: 11, title: 'Evening Programme'),
    CreditProgrammeOption(id: 12, title: 'Weekend Programme'),
  ];

  /// The languages the sample club translates its texts into: Hindi and
  /// Marathi.
  static const List<String> languages = ['hi', 'mr'];

  /// The sample member, as the user forms take a member: field id to value.
  static Map<String, dynamic> get member => {
    UserFormFields.firstNameId: 'Sam',
    UserFormFields.middleNameId: 'Q',
    UserFormFields.lastNameId: 'Sample',
    UserFormFields.nicknameId: 'Sammy',
    UserFormFields.useNamePubliclyId: true,
    UserFormFields.isPublicProfileId: false,
    UserFormFields.genderId: SignupGender.other,
    UserFormFields.dateOfBirthUtcId: DateTime.utc(2010, 3, 4),
    UserFormFields.addrLine1Id: '12 Example Street',
    UserFormFields.addrLine2Id: 'Block B',
    UserFormFields.cityId: 'Pune',
    UserFormFields.stateId: 'Maharashtra',
    UserFormFields.pincodeId: '411001',
    UserFormFields.phoneId: '+12025550143',
    UserFormFields.emailId: 'sam@example.test',
    UserFormFields.emergencyContactNameId: 'Pat Sample',
    UserFormFields.emergencyContactRelationId:
        UserFormAssembly.emergencyRelations.first,
    UserFormFields.emergencyContactPhoneId: '+12025550144',
    UserFormFields.medicalInfoId: 'None known',
  };
}
