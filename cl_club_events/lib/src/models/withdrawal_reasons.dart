/// The `withdrawalReason` the server records when a mark used up a trial
/// member's credit and removed them (club_server `TRIAL_CREDIT_EXHAUSTED`,
/// club_core#98, #100). Any other reason is free text an admin wrote, so a
/// trial that ended is told apart by this code alone, never by `isTrial`.
const String trialCreditExhaustedReason = 'trialCreditExhausted';

/// Whether [withdrawalReason] says a trial ended because its credit ran out.
bool isTrialCreditExhausted(String? withdrawalReason) =>
    withdrawalReason == trialCreditExhaustedReason;
