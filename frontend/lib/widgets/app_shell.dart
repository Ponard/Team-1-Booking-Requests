import 'package:diocese_frontend/config/app_colors.dart';
import 'package:diocese_frontend/widgets/app_drawer.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentRoute,
    required this.body,
    this.toolbar,
    this.floatingActionButton,
    this.onMyBookingsReturned,
  });

  final String currentRoute;
  final Widget body;
  final PreferredSizeWidget? toolbar;
  final Widget? floatingActionButton;
  final Future<void> Function()? onMyBookingsReturned;

  @override
  Widget build(BuildContext context) {
    const desktopBreakpoint = 1024.0;
    final isWideScreen = MediaQuery.of(context).size.width >= desktopBreakpoint;

    final drawer = AppDrawer(
      currentRoute: currentRoute,
      isPermanent: isWideScreen,
      onMyBookingsReturned: onMyBookingsReturned,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SvgPicture.asset(
            //   'assets/icons/Diocese-of-Kalookan-Logo.svg',
            //   height: 36,
            // ),
            // SizedBox(width: 12),
            Expanded(
              child: Text(
                'RCDOK Booking System',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // TODO: replace with notifications?
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     tooltip: 'Logout',
        //     onPressed: () async {
        //       await authProvider.logout();

        //       if (context.mounted) {
        //         Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        //       }
        //     },
        //   ),
        // ],
      ),
      drawer: isWideScreen
          ? null
          : Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight:
                      Radius.circular(0.0), // or adjust to your preference
                  bottomRight: Radius.circular(0.0),
                ),
              ),
              child: drawer,
            ),
      body: isWideScreen
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 280,
                  child: drawer,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      if (toolbar != null)
                        SizedBox(
                          height: toolbar!.preferredSize.height,
                          child: toolbar!,
                        ),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                if (toolbar != null)
                  SizedBox(
                    height: toolbar!.preferredSize.height,
                    child: toolbar!,
                  ),
                Expanded(child: body),
              ],
            ),
    );
  }
}
