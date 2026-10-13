import 'package:club_sdk_2/club_sdk_2.dart';

/// [addr] on one line: its lines, city, state and pincode that are filled
/// in, separated by commas.
String formatUserAddress(Address addr) {
  return [
    addr.addrLine1,
    addr.addrLine2,
    addr.city,
    addr.state,
    addr.pincode,
  ].where((s) => s != null && s.isNotEmpty).join(', ');
}
