import 'dart:convert';

import 'package:meta/meta.dart';

import 'contact_form_labels.dart';
import 'contact_info_labels.dart';
import 'contact_map_labels.dart';

/// Contact page labels (form, info, map sections).
///
/// Separate from PageData to allow reuse of PageDataScaffold.
@immutable
class ContactPageLabels {
  const ContactPageLabels({
    required this.form,
    required this.info,
    required this.map,
  });

  factory ContactPageLabels.fromMap(Map<String, dynamic> map) {
    return ContactPageLabels(
      form: ContactFormLabels.fromMap(
        map['form'] as Map<String, dynamic>? ?? {},
      ),
      info: ContactInfoLabels.fromMap(
        map['info'] as Map<String, dynamic>? ?? {},
      ),
      map: ContactMapLabels.fromMap(map['map'] as Map<String, dynamic>? ?? {}),
    );
  }

  factory ContactPageLabels.fromJson(String source) =>
      ContactPageLabels.fromMap(json.decode(source) as Map<String, dynamic>);

  final ContactFormLabels form;
  final ContactInfoLabels info;
  final ContactMapLabels map;

  ContactPageLabels copyWith({
    ContactFormLabels? form,
    ContactInfoLabels? info,
    ContactMapLabels? map,
  }) {
    return ContactPageLabels(
      form: form ?? this.form,
      info: info ?? this.info,
      map: map ?? this.map,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'form': form.toMap(),
      'info': info.toMap(),
      'map': map.toMap(),
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'ContactPageLabels(form: $form, info: $info, map: $map)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactPageLabels &&
        other.form == form &&
        other.info == info &&
        other.map == map;
  }

  @override
  int get hashCode => form.hashCode ^ info.hashCode ^ map.hashCode;
}
