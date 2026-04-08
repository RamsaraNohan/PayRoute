import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/post_login_result.dart';
import '../../passenger/home/passenger_dashboard.dart';
import '../../crew/dashboard/conductor_dashboard.dart';
import '../../driver/dashboard/driver_dashboard.dart';
import '../../owner/dashboard/owner_dashboard.dart';
import '../../admin/admin_dashboard.dart';
import 'registration_screen.dart';
import '../../auth/role_selection_screen.dart';
import '../../auth/status/verification_pending_screen.dart';
import '../../auth/status/verification_rejected_screen.dart';
import '../../auth/status/banned_screen.dart';
import '../../auth/role_switch_screen.dart';
import '../../auth/staff_invite_screen.dart';

class RoleRouter extends StatefulWidget {
  final Uri? initialUri;
  const RoleRouter({super.key, this.initialUri});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late Future<PostLoginResult?> _postLoginFuture;

  @override
  void initState() {
    super.initState();
    _postLoginFuture = _getPostLoginResult();
  }

  Future<PostLoginResult?> _getPostLoginResult() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    // Handle Deep Link Invitation
    if (widget.initialUri != null) {
      if (widget.initialUri!.host == 'invite' || widget.initialUri!.host == 'join') {
        final inviteId = widget.initialUri!.queryParameters['id'];
        if (inviteId != null) {
           return HasStaffInvite({'inviteId': inviteId}); // Minimal data for screen to fetch rest
        }
      }
    }

    final authService = AuthService();
    return await authService.handlePostLogin(user.uid, user.phoneNumber ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostLoginResult?>(
      future: _postLoginFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: AppTheme.gradientBackground(),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final result = snapshot.data;

        if (result == null || result is NeedsRoleSelection) {
          // TODO: point to new role selection, but for now just use standard pass-through or placeholder
          // since role_selection_screen.dart is in Phase 4. We will import and route to it once ready.
          // Replacing RegistrationScreen.
        }

        return _buildNavFromResult(result);
      },
    );
  }

  Widget _buildNavFromResult(PostLoginResult? result) {
    if (result == null || result is NeedsRoleSelection) {
      return const RoleSelectionScreen();
    }
    
    if (result is AccountBanned) {
      return const BannedScreen();
    }
    if (result is AccountSuspended) {
      return const BannedScreen(); // For now use same screen
    }
    if (result is VerificationPending) {
      return const VerificationPendingScreen();
    }
    if (result is VerificationRejected) {
      return VerificationRejectedScreen(reason: result.reason);
    }
    if (result is MultipleRoles) {
      return RoleSwitchScreen(availableRoles: result.roles);
    }
    if (result is HasStaffInvite) {
      return StaffInviteScreen(inviteData: result.inviteData);
    }
    if (result is MultipleRoles) {
      // Phase 7 will add RoleSwitchScreen.
      // For now, default to first role
      return _getDashboardForRole(result.roles.first);
    }
    if (result is GoToDashboard) {
      return _getDashboardForRole(result.role);
    }
    
    return const PassengerDashboard();
  }

  Widget _getDashboardForRole(String role) {
    switch (role) {
      case 'conductor':
        return const ConductorDashboard();
      case 'driver':
        return const DriverDashboard();
      case 'owner':
        return const OwnerDashboard();
      case 'admin':
        return const AdminDashboard();
      case 'passenger':
      default:
        return const PassengerDashboard();
    }
  }
}
