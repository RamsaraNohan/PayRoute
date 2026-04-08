/// Sealed class representing all possible outcomes after a user logs in.
///
/// Used by [AuthService.handlePostLogin] and consumed by [OTPEntryScreen]
/// and [RoleRouter] to determine where to navigate.
sealed class PostLoginResult {
  const PostLoginResult();
}

/// Brand-new user with no roles — needs to pick a role and register.
class NeedsRoleSelection extends PostLoginResult {
  const NeedsRoleSelection();
}

/// User has exactly one role and all checks passed — go to their dashboard.
class GoToDashboard extends PostLoginResult {
  final String role;
  const GoToDashboard(this.role);
}

/// User has multiple roles — show the role-switch screen.
class MultipleRoles extends PostLoginResult {
  final List<String> roles;
  const MultipleRoles(this.roles);
}

/// Account is permanently banned.
class AccountBanned extends PostLoginResult {
  const AccountBanned();
}

/// Account is temporarily suspended.
class AccountSuspended extends PostLoginResult {
  const AccountSuspended();
}

/// Professional verification was rejected (e.g. invalid license photo).
class VerificationRejected extends PostLoginResult {
  final String reason;
  const VerificationRejected(this.reason);
}

/// Professional verification is still in progress.
class VerificationPending extends PostLoginResult {
  const VerificationPending();
}

/// User has a pending staff invite from an owner.
class HasStaffInvite extends PostLoginResult {
  final Map<String, dynamic> inviteData;
  const HasStaffInvite(this.inviteData);
}
