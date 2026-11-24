import 'package:coyhaique_basecamp_pt/core/widgets/basecamp/bc_scroll_back_bar.dart';
import 'package:coyhaique_basecamp_pt/core/widgets/basecamp/bc_widgets.dart';
import 'package:coyhaique_basecamp_pt/core/widgets/bottom_nav_bar.dart';
import 'package:coyhaique_basecamp_pt/features/planner/presentation/widgets/planner_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child, double scale) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  ),
);

void _viewport(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 700);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final width in [320.0, 360.0, 430.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('BcButton: $width dp / $scale text', (tester) async {
        _viewport(tester, width);
        const label = 'Guardar los cambios de mi itinerario';
        var presses = 0;
        await tester.pumpWidget(_app(
          Center(child: SizedBox(
            width: 160,
            child: BcButton(label: label, icon: Icons.bookmark_add, onPressed: () => presses++),
          )),
          scale,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(48));
        expect(tester.widget<Text>(find.text(label)).overflow, isNot(TextOverflow.ellipsis));
        await tester.tap(find.text(label));
        expect(presses, 1);
      });
    }
  }

  testWidgets('Volver stays reachable after scrolling at 200% text', (tester) async {
    _viewport(tester, 320);
    var backs = 0;
    await tester.pumpWidget(_app(BcPinnedBackLayout(
      title: 'Ficha de un destino con nombre muy largo',
      backLabel: 'Volver',
      onBack: () => backs++,
      child: ListView.builder(itemCount: 50, itemBuilder: (_, i) => ListTile(title: Text('Lugar $i'))),
    ), 2));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byTooltip('Volver'));
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byTooltip('Volver')), before);
    await tester.tap(find.byTooltip('Volver'));
    expect(backs, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Long planner chip and notice fit narrow screens', (tester) async {
    _viewport(tester, 320);
    await tester.pumpWidget(_app(Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Wrap(children: [PlannerFilterChip(label: 'Actividades de naturaleza y aventura', selected: true, onTap: () {})]),
        PlannerNotice(icon: Icons.info_outline, text: 'No pudimos obtener tu ubicación.', actionLabel: 'Abrir configuración del dispositivo', onAction: () {}),
      ]),
    ), 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Abrir configuración del dispositivo'), findsOneWidget);
  });

  testWidgets('Navigation retains all four actions in compact mode', (tester) async {
    _viewport(tester, 320);
    var selected = 0;
    await tester.pumpWidget(ProviderScope(child: _app(
      Align(alignment: Alignment.bottomCenter, child: GlassNavBar(currentIndex: 0, onTap: (i) => selected = i)),
      2,
    )));
    await tester.pumpAndSettle();
    expect(find.byType(TextButton), findsNWidgets(4));
    await tester.tap(find.byTooltip('Perfil'));
    expect(selected, 3);
    expect(tester.takeException(), isNull);
  });
}
