import 'package:flutter/material.dart';
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
    "Simular aposta",
    "Aposta segura",
    "Recuperar aposta",
    "Navegar",
    "Historico ",
  ];

  List menuIcons = [
    Icons.sports_score,
    Icons.sports_outlined,
    Icons.sports_soccer_outlined,
    Icons.public,
    Icons.insert_chart,
  ];

  List menuIconCollors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];

  List pages = [
    const SimulatePage(),
    const SureBetPage(),
    const ReturnBetPage(),
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
          padding: const EdgeInsets.all(8.0),

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
                    Theme.of(context).cardTheme.color!.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  width: 1,
                ),
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
                            color: menuIconCollors[index].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            menuIcons[index],
                            size: 40,
                            color: menuIconCollors[index],
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
