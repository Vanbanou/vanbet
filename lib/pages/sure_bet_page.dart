import 'package:flutter/material.dart';
import 'package:vanbet/dialogs/result_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SureBetPage extends StatefulWidget {
  const SureBetPage({super.key});

  @override
  State<SureBetPage> createState() => _SureBetPageState();
}

class _SureBetPageState extends State<SureBetPage> {
  List<double> _oddList = []; // Lista de odds
  final TextEditingController _oddsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _focusNodeAmountTextfield = FocusNode();

  double _totalAmount = 0; // Valor total da aposta
  double _totalReturn = 0; // Retorno total esperado
  double _profitOrLoss = 0; // Lucro ou perda
  Map<String, double> _distributions =
      {}; // Distribuições calculadas para sure bets

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _oddsController.dispose();
    _amountController.dispose();
    _focusNodeAmountTextfield.dispose();
    super.dispose();
  }

  // Carregar os dados salvos do SharedPreferences
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Carregar as odds e montante
    List<String>? oddsString = prefs.getStringList('oddsListSure');
    if (oddsString != null) {
      setState(() {
        _oddList.addAll(oddsString.map((e) => double.tryParse(e) ?? 0.0));
      });
    }

    double amount = prefs.getDouble('totalAmountSure') ?? 0.0;
    _amountController.text = amount == 0 ? "" : amount.toString();
    _calculateSureBet();
  }

  // Salvar os dados no SharedPreferences
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Salvar odds
    List<String> oddsString = _oddList.map((e) => e.toString()).toList();
    prefs.setStringList('oddsListSure', oddsString);

    // Salvar o montante
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    prefs.setDouble('totalAmountSure', amount);
  }

  // Função para calcular as distribuições das apostas e resultados
  void _calculateSureBet() {
    setState(() {
      // Certifica que o montante é válido
      _totalAmount = double.tryParse(_amountController.text) ?? 0;

      if (_totalAmount > 0 && _oddList.isNotEmpty) {
        // Soma dos inversos das odds
        double inverseSum = _oddList.fold(0, (sum, odd) => sum + 1 / odd);

        // Distribui os valores proporcionalmente para cada odd
        _distributions = {
          for (int i = 0; i < _oddList.length; i++)
            "Aposta ${i + 1}": (_totalAmount / _oddList[i]) / inverseSum,
        };

        // Calcula o retorno total esperado
        _totalReturn = _totalAmount / inverseSum;

        // Calcula lucro ou perda
        _profitOrLoss = _totalReturn - _totalAmount;
      } else {
        // Reseta os valores se os dados forem inválidos
        _distributions.clear();
        _totalReturn = 0;
        _profitOrLoss = 0;
      }
      _saveData(); // Salva os dados ao recalcular
    });
  }

  void _cleanAll() {
    setState(() {
      _oddList = []; // Lista de odds
      _oddsController.clear();
      _amountController.clear();

      _totalAmount = 0; // Valor total da aposta
      _totalReturn = 0; // Retorno total esperado
      _profitOrLoss = 0; // Lucro ou perda
      _distributions = {}; // Distribuições calculadas para sure bets
    });
    _saveData(); // Salva os dados ao recalcular
  }

  // Função para mostrar o diálogo de resultados detalhados
  void _showDetailedResults() {
    showDialog(
      context: context,
      builder: (context) {
        return ResultDialog(
          title: "Detalhes da Distribuição",
          items: _distributions.entries.map((entry) {
            final oddIndex = _distributions.keys.toList().indexOf(entry.key);
            final currentOdd =
                _oddList[oddIndex]; // Recupera a odd correspondente

            return DetailItem(
              title: "Odd ${oddIndex + 1} (${currentOdd.toStringAsFixed(2)})",
              subtitle: "Apostar: ${entry.value.toStringAsFixed(2)} Kz",
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aposta Segura"),
        actions: [
          IconButton(
            onPressed: _cleanAll,
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: "Limpar tudo",
          ),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Verifique se existe oportunidade de arbitragem (Sure Bet).",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildInputSection(theme),
              const SizedBox(height: 4),
              _oddList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          "Nenhuma odd adicionada",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _oddList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.primaryColor.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              "Odd ${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _oddList[index].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // Remove a odd e recalcula
                                    setState(() {
                                      _oddList.removeAt(index);
                                      _calculateSureBet();
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 4),
              _buildSummaryCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _oddsController,
                    decoration: InputDecoration(
                      labelText: "Adicionar Odd",
                      prefixIcon: const Icon(Icons.show_chart_sharp),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            double? newOddValue = double.tryParse(
                              _oddsController.text,
                            );
                            if (newOddValue != null && newOddValue > 1) {
                              _oddList.add(newOddValue);
                              _oddsController.clear();
                              _calculateSureBet();
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onSubmitted: (_) =>
                        _focusNodeAmountTextfield.requestFocus(),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              focusNode: _focusNodeAmountTextfield,
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Montante Total (Kz)",
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calculateSureBet(),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final isProfitable = _profitOrLoss >= 0;
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Retorno Total",
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  "${_totalReturn.toStringAsFixed(2)} Kz",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isProfitable ? "Lucro Garantido" : "Perda Estimada",
                  style: TextStyle(
                    color: isProfitable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${isProfitable ? '+' : ''}${_profitOrLoss.toStringAsFixed(2)} Kz",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isProfitable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_distributions.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showDetailedResults,
                  icon: const Icon(Icons.list_alt),
                  label: const Text("Ver Detalhes da Distribuição"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.cardTheme.color,
                    foregroundColor: theme.primaryColor,
                    elevation: 0,
                    side: BorderSide(color: theme.primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
