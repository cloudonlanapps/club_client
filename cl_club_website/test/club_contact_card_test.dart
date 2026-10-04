import 'package:cl_club_website/src/page_content/contact/contact_info_labels.dart';
import 'package:cl_club_website/src/widgets/club_contact_card.dart';
import 'package:cl_club_website/src/widgets/instagram_qr_tile.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ContactInfo, contactInfoProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show LocalizedText;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _contact = ContactInfo(
  clubName: 'Test Club',
  phoneNumber: '+911234567890',
  email: 'club@example.test',
  addressLine1: LocalizedText('1 Rink Road'),
  city: LocalizedText('Pune'),
  postalCode: '411000',
  instagramUrl: 'https://instagram.example.test/club',
);

const _labels = ContactInfoLabels(
  title: 'Get in touch',
  addressLabel: 'Address',
  phoneLabel: 'Phone',
  emailLabel: 'Email',
  followUsLabel: 'Follow us',
  qrCodeHint: 'Scan',
);

void main() {
  testWidgets('Issue 53: ClubContactCard shows contactInfoProvider', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactInfoProvider.overrideWithValue(_contact)],
        child: const ShadApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClubContactCard(
                labels: _labels,
                whatsappLabel: 'WhatsApp',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('+911234567890'), findsNWidgets(2));
    expect(find.text('club@example.test'), findsOneWidget);
    expect(find.text('1 Rink Road\nPune, 411000'), findsOneWidget);
    expect(
      tester.widget<InstagramQrTile>(find.byType(InstagramQrTile)).instagramUrl,
      'https://instagram.example.test/club',
    );
  });
}
