import 'package:flutter/material.dart';
import 'ui/pages/charts_page.dart';
import 'ui/pages/settings_page.dart';

class FiwareChartsApp extends StatefulWidget {
  const FiwareChartsApp({super.key});

  @override
  State<FiwareChartsApp> createState() => _FiwareChartsAppState();
}

class _FiwareChartsAppState extends State<FiwareChartsApp> {
  int _index = 0;

  final _pages = const [ChartsPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorSchemeSeed: const Color.fromARGB(255, 92, 192, 207),
      useMaterial3: true,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'FIWARE Charts',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(child: _pages[_index]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              selectedIcon: Icon(Icons.stacked_line_chart_rounded),
              label: 'Gráficos',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Config.',
            ),
          ],
          onDestinationSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
