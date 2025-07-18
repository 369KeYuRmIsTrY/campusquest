import 'package:flutter/material.dart';
import 'package:campusquest/theme/theme.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userEmail;
  final VoidCallback? onNotificationPressed;
  final Widget? leading;
  final bool showSearch;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final VoidCallback? onSearchToggle;
  final bool isSearching;

  const CommonAppBar({
    Key? key,
    required this.title,
    required this.userEmail,
    this.onNotificationPressed,
    this.leading,
    this.showSearch = false,
    this.searchController,
    this.onSearchChanged,
    this.onSearchToggle,
    this.isSearching = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      shape:ShapeBorder.lerp(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        1.0,
      ),
      elevation: 0,
      backgroundColor: AppTheme.yachtClubBlue,
      title:
          showSearch && isSearching
              ? TextField(
                controller: searchController,
                style: const TextStyle(color: AppTheme.yachtClubLight),
                cursorColor: AppTheme.yachtClubLight,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: AppTheme.yachtClubLight.withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.yachtClubLight,
                  ),
                  filled: true,
                  fillColor: AppTheme.yachtClubLight.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: onSearchChanged,
              )
              : Text(
                title,
                style: const TextStyle(
                  color: AppTheme.yachtClubLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
      leading: leading,
      actions: [
        if (showSearch)
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: AppTheme.yachtClubLight,
            ),
            onPressed: onSearchToggle,
          ),
        Row(
          children: [
            // Display user email
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                userEmail,
                style: const TextStyle(
                  color: AppTheme.yachtClubLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Notification icon
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.yachtClubLight,
              ),
              onPressed: onNotificationPressed,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AnimatedDrawer extends StatefulWidget {
  final Widget header;
  final List<Widget> menuItems;

  const AnimatedDrawer({
    Key? key,
    required this.header,
    required this.menuItems,
  }) : super(key: key);

  @override
  State<AnimatedDrawer> createState() => _AnimatedDrawerState();
}

class _AnimatedDrawerState extends State<AnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimations = List.generate(widget.menuItems.length, (index) {
      final start = index * 0.08;
      final end = start + 0.5;
      return Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.yachtClubBlue,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.yachtClubBlue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Remove or comment out the CircleAvatar:
                // CircleAvatar(
                //   radius: 30,
                //   backgroundImage: AssetImage('assets/admin.png'),
                //   backgroundColor: Colors.transparent,
                // ),
                SizedBox(
                  height: 10,
                ), // Optional: remove if you don't want extra space
                Text(
                  'Admin',
                  style: TextStyle(
                    color: AppTheme.yachtClubLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin',
                  style: TextStyle(
                    color: AppTheme.yachtClubLight.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.menuItems.length,
              itemBuilder: (context, index) {
                return ScaleTransition(
                  scale: _scaleAnimations[index],
                  child: widget.menuItems[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
