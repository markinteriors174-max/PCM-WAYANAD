// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';

enum SubscriptionAccessState {
  adminUnrestricted,
  freeTrialActive,
  graceWarning,
  lockedNeedPayment,
  activePaidYear,
}

class SubscriptionStatusResult {
  final SubscriptionAccessState state;
  final int daysRemainingInPhase;
  final DateTime? expiresAt;

  const SubscriptionStatusResult({
    required this.state,
    required this.daysRemainingInPhase,
    this.expiresAt,
  });
}

SubscriptionStatusResult evaluateSubscriptionStatus({
  required String? userEmail,
  required String adminEmail,
  required DateTime accountStartedAt,
  DateTime? paidUntil,
  DateTime? nowOverride,
}) {
  final normalizedUser = (userEmail ?? '').trim().toLowerCase();
  final normalizedAdmin = adminEmail.trim().toLowerCase();
  if (normalizedUser.isNotEmpty && normalizedUser == normalizedAdmin) {
    return const SubscriptionStatusResult(
      state: SubscriptionAccessState.adminUnrestricted,
      daysRemainingInPhase: 9999,
    );
  }

  final now = nowOverride ?? DateTime.now();

  if (paidUntil != null && now.isBefore(paidUntil)) {
    final daysLeft = paidUntil.difference(now).inDays.clamp(0, 3650);
    return SubscriptionStatusResult(
      state: SubscriptionAccessState.activePaidYear,
      daysRemainingInPhase: daysLeft,
      expiresAt: paidUntil,
    );
  }

  final trialEnd = accountStartedAt.add(const Duration(days: 60));
  if (now.isBefore(trialEnd)) {
    final trialDaysLeft = trialEnd.difference(now).inDays.clamp(0, 60);
    return SubscriptionStatusResult(
      state: SubscriptionAccessState.freeTrialActive,
      daysRemainingInPhase: trialDaysLeft,
      expiresAt: trialEnd,
    );
  }

  final warningEnd = trialEnd.add(const Duration(days: 10));
  if (now.isBefore(warningEnd)) {
    final warningDaysLeft = warningEnd.difference(now).inDays.clamp(0, 10);
    return SubscriptionStatusResult(
      state: SubscriptionAccessState.graceWarning,
      daysRemainingInPhase: warningDaysLeft,
      expiresAt: warningEnd,
    );
  }

  return SubscriptionStatusResult(
    state: SubscriptionAccessState.lockedNeedPayment,
    daysRemainingInPhase: 0,
    expiresAt: warningEnd,
  );
}
