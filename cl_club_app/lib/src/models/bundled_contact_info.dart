import 'dart:convert';

import 'package:cl_remote_store/cl_remote_store.dart' show ContactInfo;
import 'package:flutter/services.dart' show rootBundle;

import 'club_config.dart';

/// Reads the club's bundled contact details ([kClubContactAsset]), which
/// `clubMain` puts under cl_remote_store's `contactInfoProvider` as the
/// fallback for every field the server leaves out.
Future<ContactInfo> loadBundledContactInfo() async => ContactInfo.fromBundled(
  json.decode(await rootBundle.loadString(kClubContactAsset))
      as Map<String, dynamic>,
);
