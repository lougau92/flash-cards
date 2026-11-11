import 'package:flutter/material.dart'
    show
        AutomaticKeepAliveClientMixin,
        BuildContext,
        Curves,
        NavigationBar,
        NavigationDestination,
        PageController,
        PageView,
        PreferredSizeWidget,
        Scaffold,
        State,
        StatefulWidget,
        Widget;

class SwipeNavigation extends StatefulWidget {
  const SwipeNavigation({
    super.key,
    required this.screens,
    required this.destinations,
    this.appBar,
  });

  final List<Widget> screens;
  final List<NavigationDestination> destinations;
  final PreferredSizeWidget? appBar;

  @override
  State<SwipeNavigation> createState() => _SwipeNavigationState();
}

class _SwipeNavigationState extends State<SwipeNavigation> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.appBar,
        body: PageView(
          controller: _controller,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            for (final screen in widget.screens) _KeptPage(child: screen),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => _controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          ),
          destinations: widget.destinations,
        ),
      );
}

class _KeptPage extends StatefulWidget {
  const _KeptPage({required this.child});

  final Widget child;

  @override
  State<_KeptPage> createState() => _KeptPageState();
}

class _KeptPageState extends State<_KeptPage>
    with AutomaticKeepAliveClientMixin<_KeptPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
