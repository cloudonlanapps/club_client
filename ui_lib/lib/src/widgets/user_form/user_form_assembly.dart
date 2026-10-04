import 'package:ui_lib/src/widgets/user_form/form_address.dart';

/// Pure, SDK-free assembly helpers for the user form.
///
/// They translate between the form's flat fields and the wire-shaped values
/// the caller's adapter passes to / receives from the SDK. The caller
/// (`cl_club_members` `user_form_helpers.dart`) owns the SDK boundary;
/// these helpers deal only in `String`, `DateTime`, and [FormAddress].
class UserFormAssembly {
  const UserFormAssembly._();

  /// Emergency contact relation options.
  static const List<String> emergencyRelations = [
    'Parent',
    'Spouse',
    'Sibling',
    'Child',
    'Friend',
    'Other',
  ];

  /// Merges 3 emergency contact fields into `"Name (Relation) : Phone"`.
  ///
  /// Returns `null` if all fields are empty.
  static String? mergeEmergencyContact({
    String? name,
    String? relation,
    String? phone,
  }) {
    final n = name?.trim() ?? '';
    final r = relation?.trim() ?? '';
    final p = phone?.trim() ?? '';

    if (n.isEmpty && r.isEmpty && p.isEmpty) return null;

    final parts = <String>[];
    if (n.isNotEmpty) {
      parts.add(r.isNotEmpty ? '$n ($r)' : n);
    } else if (r.isNotEmpty) {
      parts.add('($r)');
    }
    if (p.isNotEmpty) parts.add(p);
    return parts.join(' : ');
  }

  /// Parses `"Name (Relation) : Phone"` back into 3 parts.
  static ({String? name, String? relation, String? phone})
  parseEmergencyContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return (name: null, relation: null, phone: null);
    }

    final colonIndex = value.indexOf(' : ');
    String nameRelation;
    String phone;

    if (colonIndex >= 0) {
      nameRelation = value.substring(0, colonIndex).trim();
      phone = value.substring(colonIndex + 3).trim();
    } else {
      nameRelation = value.trim();
      phone = '';
    }

    final relationMatch = RegExp(r'\((\w+)\)').firstMatch(nameRelation);
    String? relation;
    var name = nameRelation;

    if (relationMatch != null) {
      final candidate = relationMatch.group(1)!;
      if (emergencyRelations.contains(candidate)) {
        relation = candidate;
      }
      name = nameRelation.replaceAll(relationMatch.group(0)!, '').trim();
    }

    return (
      name: name.isEmpty ? null : name,
      relation: relation,
      phone: phone.isEmpty ? null : phone,
    );
  }

  /// Builds a [FormAddress] from flat fields. Returns `null` if all are empty.
  static FormAddress? assembleAddress({
    String? addrLine1,
    String? addrLine2,
    String? city,
    String? state,
    String? pincode,
  }) {
    final a = FormAddress(
      addrLine1: addrLine1,
      addrLine2: addrLine2,
      city: city,
      state: state,
      pincode: pincode,
    );
    return a.isEmpty ? null : a;
  }

  /// Floors a picked date to UTC midnight of the same calendar day.
  ///
  /// Date pickers (notably `CLDatePickerFormField`) emit a *local* `DateTime`
  /// for what the user perceives as a pure date (e.g. a DOB). Storing that
  /// as an instant produces off-by-one-day bugs whenever the device's TZ
  /// differs from UTC. Flooring on submit makes the wire value match the
  /// calendar date the user picked.
  static DateTime? floorToUtcMidnight(DateTime? d) {
    if (d == null) return null;
    return DateTime.utc(d.year, d.month, d.day);
  }

  /// Converts empty strings to `null` for optional text fields.
  static String? maybe(String key, Map<String, dynamic> values) {
    final raw = (values[key] as String?)?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }
}
