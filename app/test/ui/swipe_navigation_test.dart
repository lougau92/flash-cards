import 'package:app/ui/widgets/swipe_navigation.dart' show SwipeNavigation;
import 'package:flutter/material.dart'
    show
        Icon,
        Icons,
        ListView,
        MaterialApp,
        NavigationBar,
        NavigationDestination,
        Offset,
        PageView,
        Scaffold,
        Size,
        SizedBox,
        Text,
        TextField;
import 'package:flutter_test/flutter_test.dart'
    show
        WidgetTester,
        addTearDown,
        expect,
        find,
        findsOneWidget,
        isNull,
        testWidgets;

Future<void> _mount(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SwipeNavigation(
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.play_arrow), label: 'Workspace'),
          NavigationDestination(
              icon: Icon(Icons.history), label: 'Run History'),
        ],
        screens: [
          ListView(children: [
            const TextField(),
            for (var i = 0; i < 20; i++)
              SizedBox(height: 100, child: Text('Source paragraph $i')),
          ]),
          const Text('Saved summaries'),
        ],
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

int _selected(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> _swipe(WidgetTester tester, double distance) async {
  await tester.drag(find.byType(PageView), Offset(distance, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone swipes switch pages and update the navigation bar',
      _swipesBothWays);
  testWidgets('navigation taps and swipes stay synchronized', _tapsAndSwipes);
  testWidgets('vertical scrolling keeps the page and preserves its position',
      _preservesScroll);
}

Future<void> _swipesBothWays(WidgetTester tester) async {
  await _mount(tester);
  await tester.enterText(find.byType(TextField), 'Keep my draft');
  await _swipe(tester, -300);
  expect(_selected(tester), 1);
  expect(find.text('Saved summaries'), findsOneWidget);
  await _swipe(tester, 300);
  expect(_selected(tester), 0);
  expect(find.text('Keep my draft'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _tapsAndSwipes(WidgetTester tester) async {
  await _mount(tester);
  await tester.tap(find.byIcon(Icons.history));
  await tester.pumpAndSettle();
  expect(_selected(tester), 1);
  await _swipe(tester, 300);
  expect(_selected(tester), 0);
  await _swipe(tester, -300);
  await tester.tap(find.byIcon(Icons.play_arrow));
  await tester.pumpAndSettle();
  expect(_selected(tester), 0);
  expect(tester.takeException(), isNull);
}

Future<void> _preservesScroll(WidgetTester tester) async {
  await _mount(tester);
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pumpAndSettle();
  expect(_selected(tester), 0);
  final paragraph = find.text('Source paragraph 8');
  final before = tester.getTopLeft(paragraph);
  await _swipe(tester, -300);
  await _swipe(tester, 300);
  expect(tester.getTopLeft(paragraph), before);
  expect(tester.takeException(), isNull);
}
