import 'package:cl_club_forms/cl_club_forms.dart' show InquiryChoice;
import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../page_content/site_copy.dart';
import '../widgets/inquiry_view.dart';
import '../widgets/public_page_shell.dart';

/// Where the event cards' "Register Now" and "Join Now" land.
///
/// It was a "Coming Soon" page that sent people to Contact Us — one more step
/// between someone deciding to join and the club hearing about it. It is an
/// interest form now: no account, no payment, just the details the club needs
/// to call back about the right batch.
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final strings = SiteCopy.of(context).strings;

    return PublicPageShell(
      pageTitle: 'Join Our Club',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 60 : 100,
                horizontal: isMobile ? 24 : 48,
              ),
              color: theme.colorScheme.primary,
              child: Column(
                children: [
                  Icon(
                    LucideIcons.userPlus,
                    size: isMobile ? 48 : 64,
                    color: theme.colorScheme.primaryForeground,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.interestHeroTitle,
                    style: theme.textTheme
                        .heroTitle(isMobile: isMobile)
                        .copyWith(color: theme.colorScheme.primaryForeground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.interestHeroSubtitle,
                    style: theme.textTheme
                        .heroSubtitle(
                          isMobile: isMobile,
                          color: theme.colorScheme.primaryForeground,
                        )
                        .copyWith(fontSize: isMobile ? 16 : 18),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 72,
                horizontal: isMobile ? 16 : 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: InquiryView(
                    kind: InquiryKind.interest,
                    title: strings.interestFormTitle,
                    description: strings.interestFormDescription,
                    messageLabel: strings.interestFormMessageLabel,
                    messagePlaceholder: strings.interestFormMessagePlaceholder,
                    submitLabel: strings.interestFormSubmitButton,
                    thanksTitle: strings.interestFormThanksTitle,
                    thanksBody: strings.interestFormThanksBody,
                    // The note is optional here: the answers below are the
                    // point, and a required free-text box turns people away.
                    messageRequired: false,
                    choices: [
                      InquiryChoice(
                        key: 'ageGroup',
                        label: strings.interestAgeGroupLabel,
                        placeholder: strings.interestAgeGroupPlaceholder,
                        options: {
                          'child': strings.interestAgeGroupChild,
                          'teen': strings.interestAgeGroupTeen,
                          'adult': strings.interestAgeGroupAdult,
                        },
                      ),
                      InquiryChoice(
                        key: 'programme',
                        label: strings.interestProgrammeLabel,
                        placeholder: strings.interestProgrammePlaceholder,
                        options: {
                          'camps': strings.interestProgrammeCamps,
                          'training': strings.interestProgrammeTraining,
                          'events': strings.interestProgrammeEvents,
                          'unsure': strings.interestProgrammeUnsure,
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
