import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemBetPage extends StatefulWidget {
  const SystemBetPage({super.key});

  @override
  State<SystemBetPage> createState() => _SystemBetPageState();
}

class _SystemBetPageState extends State<SystemBetPage> {
  final List<double> _oddsList = [];
  final List<double> _bankerList = [];

  final TextEditingController _oddsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bonusController = TextEditingController();

  bool _isPercentageBonus = false;
  bool _isAddingBanker = false;
  int _systemK = 2;

  double _totalAmount = 0;
  double _actualCost = 0;
  double _maxReturn = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- Persistência (Mesmo padrão da SureBet) ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _oddsList.addAll(
        (prefs.getStringList('oddsSys') ?? []).map(double.parse),
      );
      _bankerList.addAll(
        (prefs.getStringList('bankersSys') ?? []).map(double.parse),
      );
      _systemK = prefs.getInt('systemKSys') ?? 2;
      _isPercentageBonus = prefs.getBool('isPercentSys') ?? false;
      _amountController.text = prefs.getString('amountSys') ?? "";
      _bonusController.text = prefs.getString('bonusSys') ?? "";
    });
    _calculateSystem();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'oddsSys',
      _oddsList.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'bankersSys',
      _bankerList.map((e) => e.toString()).toList(),
    );
    await prefs.setInt('systemKSys', _systemK);
    await prefs.setBool('isPercentSys', _isPercentageBonus);
    await prefs.setString('amountSys', _amountController.text);
    await prefs.setString('bonusSys', _bonusController.text);
  }

  void _calculateSystem() {
    _totalAmount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    double bonusInput =
        double.tryParse(_bonusController.text.replaceAll(',', '.')) ?? 0;
    double bonusValue = _isPercentageBonus
        ? (_totalAmount * (bonusInput / 100))
        : bonusInput;
    _actualCost = (_totalAmount - bonusValue).clamp(0, double.infinity);

    if (_oddsList.length >= _systemK && _totalAmount > 0) {
      int totalCombos = _combinationsCount(_oddsList.length, _systemK);
      double stakePerCombo = _totalAmount / totalCombos;
      double bankerProduct = _bankerList.fold(1.0, (p, e) => p * e);

      List<List<int>> allCombos = _generateCombinations(
        _oddsList.length,
        _systemK,
      );
      _maxReturn = 0;
      for (var combo in allCombos) {
        double comboOdd = bankerProduct;
        for (var idx in combo) {
          comboOdd *= _oddsList[idx];
        }
        _maxReturn += (comboOdd * stakePerCombo);
      }
    } else {
      _maxReturn = 0;
    }
    setState(() {});
    _saveData();
  }

  int _combinationsCount(int n, int r) {
    if (r < 0 || r > n) return 0;
    if (r == 0 || r == n) return 1;
    if (r > n / 2) r = n - r;
    int res = 1;
    for (int i = 1; i <= r; ++i) {
      res = res * (n - i + 1) ~/ i;
    }
    return res;
  }

  List<List<int>> _generateCombinations(int n, int k) {
    List<List<int>> result = [];
    void helper(List<int> combo, int start) {
      if (combo.length == k) {
        result.add(List.from(combo));
        return;
      }
      for (int i = start; i < n; i++) {
        combo.add(i);
        helper(combo, i + 1);
        combo.removeLast();
      }
    }

    helper([], 0);
    return result;
  }

  void _addOdd() {
    final double? val = double.tryParse(
      _oddsController.text.replaceAll(',', '.'),
    );
    if (val != null && val > 1) {
      setState(() {
        if (_isAddingBanker) {
          _bankerList.add(val);
        } else {
          _oddsList.add(val);
        }
        _oddsController.clear();
        _calculateSystem();
      });
    }
  }

  void _cleanAll() {
    setState(() {
      _oddsList.clear();
      _bankerList.clear();
      _oddsController.clear();
      _amountController.clear();
      _bonusController.clear();
      _systemK = 2;
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistema & Banqueiros"),
        actions: [
          IconButton(
            onPressed: _cleanAll,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            if (_oddsList.length >= 2) _buildSystemSelector(),
            const SizedBox(height: 16),
            _buildOddsList(),
            const SizedBox(height: 16),
            if (_maxReturn > 0) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _oddsController,
              decoration: InputDecoration(
                labelText: _isAddingBanker ? "Add Banqueiro" : "Add Odd Normal",
                prefixIcon: Icon(
                  _isAddingBanker ? Icons.star : Icons.trending_up,
                  color: _isAddingBanker ? Colors.amber[700] : null,
                ),
                suffixIcon: IconButton(
                  onPressed: _addOdd,
                  icon: Icon(
                    Icons.add_circle,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSubmitted: (_) => _addOdd(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Definir como Banqueiro?",
                  style: TextStyle(fontSize: 13),
                ),
                Switch(
                  value: _isAddingBanker,
                  activeColor: Colors.amber[700],
                  onChanged: (v) => setState(() => _isAddingBanker = v),
                ),
              ],
            ),
            const Divider(),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Valor Total da Banca (Kz)",
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => _calculateSystem(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bonusController,
                    decoration: InputDecoration(
                      labelText: _isPercentageBonus
                          ? "Bónus (%)"
                          : "Bónus (Kz)",
                      prefixIcon: const Icon(Icons.card_giftcard),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _calculateSystem(),
                  ),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  isSelected: [!_isPercentageBonus, _isPercentageBonus],
                  onPressed: (index) {
                    setState(() {
                      _isPercentageBonus = index == 1;
                      _calculateSystem();
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  constraints: const BoxConstraints(
                    minHeight: 45,
                    minWidth: 45,
                  ),
                  children: const [Text("Kz"), Text("%")],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSelector() {
    return Card(
      elevation: 1,
      child: ListTile(
        title: const Text(
          "Tipo de Sistema",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        trailing: DropdownButton<int>(
          value: _systemK > _oddsList.length ? _oddsList.length : _systemK,
          underline: const SizedBox(),
          items: List.generate(_oddsList.length - 1, (index) {
            int k = index + 2;
            return DropdownMenuItem(
              value: k,
              child: Text("$k de ${_oddsList.length}"),
            );
          }),
          onChanged: (val) {
            if (val != null) {
              setState(() => _systemK = val);
              _calculateSystem();
            }
          },
        ),
      ),
    );
  }

  Widget _buildOddsList() {
    List<Widget> list = [];
    for (int i = 0; i < _bankerList.length; i++) {
      list.add(_buildListTile(_bankerList[i], i, true));
    }
    for (int i = 0; i < _oddsList.length; i++) {
      list.add(_buildListTile(_oddsList[i], i, false));
    }
    return Column(children: list);
  }

  Widget _buildListTile(double odd, int index, bool isBanker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBanker
              ? Colors.amber.withOpacity(0.1)
              : Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            isBanker ? Icons.star : Icons.check,
            size: 18,
            color: isBanker
                ? Colors.amber[800]
                : Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          "Odd ${odd.toStringAsFixed(2)} ${isBanker ? '(Banqueiro)' : ''}",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            setState(() {
              isBanker
                  ? _bankerList.removeAt(index)
                  : _oddsList.removeAt(index);
              _calculateSystem();
            });
          },
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final double profit = _maxReturn - _actualCost;
    int totalCombos = _combinationsCount(_oddsList.length, _systemK);
    double stakePerCombo = _totalAmount / totalCombos;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _resultRow(
              "Custo Real:",
              "${_actualCost.toStringAsFixed(2)} Kz",
              bold: true,
            ),
            _resultRow(
              "Aposta por Caso ($totalCombos):",
              "${stakePerCombo.toStringAsFixed(2)} Kz",
            ),
            _resultRow(
              "Máximo Retorno:",
              "${_maxReturn.toStringAsFixed(2)} Kz",
            ),
            const SizedBox(height: 8),
            _resultRow(
              "Lucro Máximo:",
              "${profit.toStringAsFixed(2)} Kz",
              bold: true,
              valueColor: profit > 0 ? Colors.green : Colors.red,
            ),
            const Divider(height: 24),
            ElevatedButton.icon(
              onPressed: _showDetailedInfo,
              icon: const Icon(Icons.bar_chart),
              label: const Text("DISTRIBUIÇÃO E CENÁRIOS"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // --- MODAL FORMATADO BASEADO NA SUA SUREBET PAGE ---
  void _showDetailedInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            int totalCombos = _combinationsCount(_oddsList.length, _systemK);
            double stakePerCombo = _totalAmount / totalCombos;
            double bankerProduct = _bankerList.fold(1.0, (p, e) => p * e);
            List<List<int>> allCombos = _generateCombinations(
              _oddsList.length,
              _systemK,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Detalhamento do Sistema",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Distribuição de apostas e cenários possíveis",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // SEÇÃO 2: CENÁRIOS
                        _sectionTitle("Cenários de Acerto"),
                        if (_bankerList.isNotEmpty)
                          _customItemCard(
                            label: "Se 1 Banqueiro falhar",
                            value: "0.00 Kz",
                            caption: "Resultado Real",
                            amount: "-${_actualCost.toStringAsFixed(2)} Kz",
                            amountColor: Colors.red,
                          ),
                        ...List.generate(_oddsList.length, (i) {
                          int m = i + 1;
                          double totalRet = 0;
                          if (m >= _systemK) {
                            List<List<int>> winning = _generateCombinations(
                              m,
                              _systemK,
                            );
                            for (var combo in winning) {
                              double cOdd = bankerProduct;
                              for (var idx in combo) {
                                cOdd *= _oddsList[idx];
                              }
                              totalRet += (cOdd * stakePerCombo);
                            }
                          }
                          double diff = totalRet - _actualCost;
                          return _customItemCard(
                            label: "Acertando $m de ${_oddsList.length}",
                            value: "${totalRet.toStringAsFixed(2)} Kz",
                            caption: "Lucro/Prejuízo Real",
                            amount:
                                "${diff > 0 ? '+' : ''}${diff.toStringAsFixed(2)} Kz",
                            amountColor: diff >= 0 ? Colors.green : Colors.red,
                          );
                        }),
                        const SizedBox(height: 24),

                        // SEÇÃO 1: DISTRIBUIÇÃO
                        _sectionTitle("Distribuição (Quanto colocar)"),
                        ...List.generate(allCombos.length, (index) {
                          double comboOdd = bankerProduct;
                          for (var idx in allCombos[index]) {
                            comboOdd *= _oddsList[idx];
                          }
                          return _customItemCard(
                            label: "Aposta ${index + 1} (${_systemK} jogos)",
                            value: "${stakePerCombo.toStringAsFixed(2)} Kz",
                            caption: "Retorno Individual",
                            amount:
                                "${(stakePerCombo * comboOdd).toStringAsFixed(2)} Kz",
                          );
                        }),
                      ],
                    ),
                  ),
                  const Divider(),
                  _resultRow(
                    "Custo Total:",
                    "${_actualCost.toStringAsFixed(2)} Kz",
                    bold: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _customItemCard({
    required String label,
    required String value,
    required String caption,
    required String amount,
    Color amountColor = Colors.green,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                caption,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
