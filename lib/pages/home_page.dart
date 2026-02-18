import 'package:flutter/material.dart';
import 'package:vanbet/pages/system_bet_page.dart';
import 'package:vanbet/pages/history_bet_page.dart';
import 'package:vanbet/pages/odds_monitor_page.dart';
import 'package:vanbet/pages/simulate_page.dart';
import 'package:vanbet/pages/sure_bet_page.dart';
import 'package:vanbet/pages/return_bet_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List menuTitles = [
    "Aposta Segura",
    "Sistema & Distribuição",
    "Recuperar Aposta",
    // "Cobertura de Múltipla",
    "Simular Múltipla",
    "Monitorar Odds",
    "Histórico",
  ];

  List menuIcons = [
    Icons.verified_user_outlined,
    Icons.account_tree_outlined,
    Icons.loop_outlined,
    Icons.add_chart_outlined,
    Icons.language_outlined,
    Icons.history_outlined,
  ];

  List menuIconColors = [
    Colors.greenAccent[700]!,
    Colors.amber[600]!,
    Colors.orangeAccent,
    Colors.tealAccent[700]!,
    Colors.blueAccent,
    Colors.cyan,
  ];

  List pages = [
    const SureBetPage(),
    const SystemBetPage(),
    const ReturnBetPage(),
    const SimulatePage(),
    OddsMonitorPage(),
    const HistoryBetPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vanbet'),
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),

          child: Image.asset('assets/icon.png'),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          //Se ajusta ao tamanho da lista
          itemCount: menuTitles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).cardTheme.color!,
                    Theme.of(context).cardTheme.color!.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  //Ao clicar no meu abre uma nova pagina.
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => pages[index]),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: menuIconColors[index].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            menuIcons[index],
                            size: 40,
                            color: menuIconColors[index],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          menuTitles[index],
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
