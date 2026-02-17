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
    "Aposta Segura", // Prioridade 1: Lucro garantido
    "Sistema & Distribuição", // Prioridade 2: Gestão de risco (SystemBetPage)
    "Recuperar Aposta", // Prioridade 3: Proteção de banca
    "Simular Múltipla", // Prioridade 4: Simulação simples
    "Monitorar Odds", // Ferramenta de apoio
    "Histórico", // Consulta
  ];

  List menuIcons = [
    Icons.verified_user_outlined, // Aposta Segura
    Icons
        .account_tree_outlined, // Sistema & Distribuição (Substituí o 'a' pelo ícone de ramificação)
    Icons.loop_outlined, // Recuperar
    Icons.add_chart_outlined, // Simular
    Icons.language_outlined, // Monitorar
    Icons.history_outlined, // Histórico
  ];
  List menuIconColors = [
    Colors.greenAccent[700]!, // Verde vibrante (Lucro)
    Colors.amber[600]!, // Ouro (Sistema)
    Colors.orangeAccent, // Laranja neon (Recuperação)
    Colors.blueAccent, // Azul elétrico (Simulação)
    Colors.cyan, // Ciano (Navegação)
    Colors
        .indigoAccent, // Roxo/Azul profundo (Histórico - muito melhor que cinza)
  ];

  List pages = [
    const SureBetPage(), // Aposta Segura
    const SystemBetPage(), // Distribuição (Sistema)
    const ReturnBetPage(), // Recuperar
    const SimulatePage(), // Simular
    OddsMonitorPage(), // Navegar
    const HistoryBetPage(), // Histórico
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
