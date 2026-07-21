import 'package:diocese_frontend/config/app_routes.dart';
import 'package:diocese_frontend/providers/auth_provider.dart';
import 'package:diocese_frontend/providers/parish_provider.dart';
import 'package:diocese_frontend/utils/role_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final bool isPermanent;
  final VoidCallback? onMyBookingsReturned;

  const AppDrawer({
    super.key,
    this.onMyBookingsReturned,
    required this.currentRoute,
    required this.isPermanent,
  });

  Future<Object?> _navigate(BuildContext context, String route) async {
    if (!isPermanent) {
      Navigator.pop(context);
    }

    if (route == currentRoute) {
      return null;
    }

    return Navigator.pushReplacementNamed(context, route);
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    Future<void> Function(Object? result)? onReturned,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: currentRoute == route,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
      onTap: () async {
        final result = await _navigate(context, route);

        if (!context.mounted) return;

        await onReturned?.call(result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final userRole = authProvider.currentUser?.role ?? Roles.parishioner;
    final isAdmin = Roles.isAdmin(userRole);
    final isDioceseLevel = Roles.isDioceseLevel(userRole);
    final isPriest = Roles.isPriest(userRole);

    return Material(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 180,
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.currentUser?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${authProvider.currentUser?.email ?? ''}\n${Roles.getRoleDisplayName(userRole)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                ),
                // Show parish info for non-diocese users
                if (authProvider.currentUser?.effectiveParishId != null &&
                    !isDioceseLevel)
                  Consumer<ParishProvider>(
                    builder: (context, parishProvider, _) {
                      final parish = parishProvider.parishes
                          .where((p) =>
                              p.id ==
                              authProvider.currentUser?.effectiveParishId)
                          .firstOrNull;
                      if (parish != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Parish: ${parish.name}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
          _buildNavTile(
            context: context,
            icon: Icons.home,
            title: 'Home',
            route: AppRoutes.home,
          ),
          // Parishioner Menu Items
          if (!isAdmin && !isPriest) ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MY ACCOUNT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildNavTile(
              context: context,
              icon: Icons.list_alt,
              title: 'My Bookings',
              route: AppRoutes.myBookings,
              onReturned: (result) async {
                if (result == true) {
                  onMyBookingsReturned?.call();
                }
              },
            ),
            _buildNavTile(
              context: context,
              icon: Icons.person,
              title: 'My Profile',
              route: AppRoutes.myProfile,
            ),
          ],
          // Priest Menu Items
          if (isPriest) ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MY SCHEDULE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildNavTile(
              context: context,
              icon: Icons.calendar_month,
              title: 'My Schedule',
              route: AppRoutes.priestSchedule,
            ),
            _buildNavTile(
              context: context,
              icon: Icons.person,
              title: 'My Profile',
              route: AppRoutes.myProfile,
            ),
          ],
          // Admin/Staff Menu Items
          if (isAdmin) ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ADMINISTRATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildNavTile(
              context: context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              route: AppRoutes.adminDashboard,
            ),
            _buildNavTile(
              context: context,
              icon: Icons.calendar_today,
              title: 'Manage Bookings',
              route: AppRoutes.adminBookings,
            ),
            if (isDioceseLevel)
              _buildNavTile(
                context: context,
                icon: Icons.church,
                title: 'Manage Parishes',
                route: AppRoutes.adminParishes,
              ),
            if (isDioceseLevel || isAdmin)
              _buildNavTile(
                context: context,
                icon: Icons.people,
                title: 'Manage Users',
                route: AppRoutes.adminUsers,
              ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
