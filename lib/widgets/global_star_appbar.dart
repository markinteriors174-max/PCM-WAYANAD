import 'package:flutter/material.dart';
import '../screens/main_navigation.dart';
import 'starfield_animation.dart';

class GlobalStarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final String? title;
  final PreferredSizeWidget? bottom;

  const GlobalStarAppBar({
    super.key,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.title,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: const StarfieldAnimation(),
      centerTitle: centerTitle,
      leading: leading ?? (Navigator.canPop(context)
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              });
            },
          )
        : IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              if (RoleNavigationShell.scaffoldKey.currentState != null) {
                RoleNavigationShell.scaffoldKey.currentState?.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          )),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 35,
            width: 35,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? 'PCM MASTER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const Text(
                  'WAYANAD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    letterSpacing: 3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
