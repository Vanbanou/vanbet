import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc, status }

class HistoryBetPage extends StatefulWidget {
  const HistoryBetPage({super.key});

  @override
  State<HistoryBetPage> createState() => _HistoryBetPageState();
}

class _HistoryBetPageState extends State<HistoryBetPage> {
  List<Map<String, dynamic>> _bets = [];
  double _bank = 0.0;
  double _totalSpent = 0.0;
  SortOption _currentSortOption = SortOption.dateDesc;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _oddController = TextEditingController();
  final TextEditingController _betTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bank = prefs.getDouble('history_bank') ?? 0.0;
      _totalSpent = prefs.getDouble('history_total_spent') ?? 0.0;

      final String? betsJson = prefs.getString('history_bets');
      if (betsJson != null) {
        try {
          final dynamic decoded = jsonDecode(betsJson);
          if (decoded is List) {
            _bets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
            for (var bet in _bets) {
              if (bet['date'] is String) {
                bet['date'] = DateTime.tryParse(bet['date']) ?? DateTime.now();
              }
            }
          }
        } catch (e) {
          debugPrint("Error loading bets: $e");
        }
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('history_bank', _bank);
    await prefs.setDouble('history_total_spent', _totalSpent);

    final betsToSave = _bets.map((bet) {
      final Map<String, dynamic> copy = Map.from(bet);
      if (bet['date'] is DateTime) {
        copy['date'] = (bet['date'] as DateTime).toIso8601String();
      } else {
        copy['date'] = bet['date'].toString();
      }
      return copy;
    }).toList();

    await prefs.setString('history_bets', jsonEncode(betsToSave));
  }

  void _addBet(String type, double amount, double odd, DateTime date) {
    setState(() {
      _bets.add({
        'type': type,
        'amount': amount,
        'odd': odd,
        'date': date,
        'status': null,
      });
      _totalSpent += amount;
      _bank -= amount; // Deduz da banca ao apostar
    });
    _saveData();
  }

  void _updateBank(double value) {
    setState(() {
      _bank += value;
    });
    _saveData();
  }

  void _markBet(int index, bool won) {
    setState(() {
      if (_bets[index]['status'] == null) {
        _bets[index]['status'] = won ? 'Ganhou' : 'Perdeu';
        if (won) {
          _bank += _bets[index]['amount'] * _bets[index]['odd'];
        }
      } else {
        // Se já tinha status, reverter antes de aplicar novo?
        // Por simplicidade, vamos permitir apenas marcar se for null.
        // Para editar status, o usuário deve "Resetar" ou "Editar".
        // Mas vamos adicionar lógica de reversão simples caso queira mudar.
        final oldStatus = _bets[index]['status'];
        final amount = _bets[index]['amount'];
        final odd = _bets[index]['odd'];

        if (oldStatus == 'Ganhou') {
          _bank -= amount * odd; // Remove o prêmio
        }

        // Aplica novo status
        _bets[index]['status'] = won ? 'Ganhou' : 'Perdeu';
        if (won) {
          _bank += amount * odd;
        }
      }
    });
    _saveData();
  }

  void _deleteBet(int index) {
    setState(() {
      final bet = _bets[index];
      final amount = bet['amount'];
      final odd = bet['odd'];
      final status = bet['status'];

      // Reverter impacto financeiro
      if (status == null) {
        // Pendente: Devolve o valor apostado para a banca e remove do total gasto
        _bank += amount;
        _totalSpent -= amount;
      } else if (status == 'Ganhou') {
        // Ganhou: Remove o prêmio da banca, devolve o valor apostado (já incluso no prêmio? não, premio é total).
        // Banca = BancaAnterior - Aposta + Premio.
        // Se deletar: Banca = Banca - Premio + Aposta.
        _bank -= (amount * odd); // Remove o ganho total
        _bank +=
            amount; // Devolve o valor da aposta original para a banca (como se nunca tivesse apostado)
        _totalSpent -= amount;
      } else if (status == 'Perdeu') {
        // Perdeu: Apenas devolve o valor apostado para a banca
        _bank += amount;
        _totalSpent -= amount;
      }

      _bets.removeAt(index);
    });
    _saveData();
  }

  void _editBet(int index) {
    final bet = _bets[index];
    _betTypeController.text = bet['type'];
    _amountController.text = bet['amount'].toString();
    _oddController.text = bet['odd'].toString();
    DateTime selectedDate = bet['date'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Aposta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _betTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Aposta',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montante (Kz)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _oddController,
                      decoration: const InputDecoration(
                        labelText: 'Odd',
                        prefixIcon: Icon(Icons.sports_score),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Data:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              '${selectedDate.toLocal()}'.split(' ')[0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final type = _betTypeController.text;
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    final odd = double.tryParse(_oddController.text) ?? 0.0;

                    if (type.isNotEmpty && amount > 0 && odd > 0) {
                      // Remove a antiga (revertendo valores)
                      _deleteBet(index);
                      // Adiciona a nova
                      _addBet(type, amount, odd, selectedDate);

                      _betTypeController.clear();
                      _amountController.clear();
                      _oddController.clear();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddBetDialog() {
    _betTypeController.clear();
    _amountController.clear();
    _oddController.clear();

    showDialog(
      context: context,
      builder: (context) {
        DateTime selectedDate = DateTime.now();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Aposta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _betTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Aposta',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montante (Kz)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _oddController,
                      decoration: const InputDecoration(
                        labelText: 'Odd',
                        prefixIcon: Icon(Icons.sports_score),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Data:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              '${selectedDate.toLocal()}'.split(' ')[0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final type = _betTypeController.text;
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    final odd = double.tryParse(_oddController.text) ?? 0.0;
                    if (type.isNotEmpty && amount > 0 && odd > 0) {
                      _addBet(type, amount, odd, selectedDate);
                      _betTypeController.clear();
                      _amountController.clear();
                      _oddController.clear();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> get _sortedBets {
    List<Map<String, dynamic>> sortedList = List.from(_bets);
    switch (_currentSortOption) {
      case SortOption.dateDesc:
        sortedList.sort((a, b) => b['date'].compareTo(a['date']));
        break;
      case SortOption.dateAsc:
        sortedList.sort((a, b) => a['date'].compareTo(b['date']));
        break;
      case SortOption.amountDesc:
        sortedList.sort((a, b) => b['amount'].compareTo(a['amount']));
        break;
      case SortOption.amountAsc:
        sortedList.sort((a, b) => a['amount'].compareTo(b['amount']));
        break;
      case SortOption.status:
        sortedList.sort((a, b) {
          String statusA = a['status'] ?? 'Pendente';
          String statusB = b['status'] ?? 'Pendente';
          return statusA.compareTo(statusB);
        });
        break;
    }
    return sortedList;
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedBets = _sortedBets;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Apostas"),
        actions: [
          IconButton(
            onPressed: _showAddBetDialog,
            icon: const Icon(Icons.add),
            tooltip: "Adicionar Aposta",
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBankrollCard(theme),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Suas Apostas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort),
                    onSelected: (SortOption result) {
                      setState(() {
                        _currentSortOption = result;
                      });
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<SortOption>>[
                          const PopupMenuItem<SortOption>(
                            value: SortOption.dateDesc,
                            child: Text('Data (Mais recente)'),
                          ),
                          const PopupMenuItem<SortOption>(
                            value: SortOption.dateAsc,
                            child: Text('Data (Mais antiga)'),
                          ),
                          const PopupMenuItem<SortOption>(
                            value: SortOption.amountDesc,
                            child: Text('Valor (Maior)'),
                          ),
                          const PopupMenuItem<SortOption>(
                            value: SortOption.amountAsc,
                            child: Text('Valor (Menor)'),
                          ),
                          const PopupMenuItem<SortOption>(
                            value: SortOption.status,
                            child: Text('Estado'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              sortedBets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          "Nenhuma aposta registrada",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedBets.length,
                      itemBuilder: (context, index) {
                        final bet = sortedBets[index];
                        final isWin = bet['status'] == 'Ganhou';
                        final isLose = bet['status'] == 'Perdeu';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isWin
                                  ? Colors.green.withOpacity(0.1)
                                  : (isLose
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1)),
                              child: Icon(
                                isWin
                                    ? Icons.check
                                    : (isLose
                                          ? Icons.close
                                          : Icons.hourglass_empty),
                                color: isWin
                                    ? Colors.green
                                    : (isLose ? Colors.red : Colors.grey),
                              ),
                            ),
                            title: Text(
                              bet['type'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${bet['amount']} Kz @ ${bet['odd']}'),
                                Text(
                                  _formatDate(bet['date']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              onSelected: (value) {
                                // Find original index in _bets
                                int originalIndex = _bets.indexOf(bet);
                                if (originalIndex == -1) return;

                                if (value == 'win') {
                                  _markBet(originalIndex, true);
                                } else if (value == 'lose') {
                                  _markBet(originalIndex, false);
                                } else if (value == 'edit') {
                                  _editBet(originalIndex);
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Confirmar Exclusão"),
                                      content: const Text(
                                        "Tem certeza que deseja excluir esta aposta? O valor será revertido para a banca.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancelar"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteBet(originalIndex);
                                          },
                                          child: const Text(
                                            "Excluir",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem(
                                    value: 'win',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Ganhou'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'lose',
                                    child: Row(
                                      children: [
                                        Icon(Icons.close, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Perdeu'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Excluir'),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simulação de adicionar fundos
          showDialog(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text("Adicionar Fundos"),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: "Valor (Kz)"),
                  keyboardType: TextInputType.number,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final val = double.tryParse(controller.text);
                      if (val != null) {
                        _updateBank(val);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Adicionar"),
                  ),
                ],
              );
            },
          );
        },

        child: const Icon(Icons.account_balance_wallet),
      ),
    );
  }

  Widget _buildBankrollCard(ThemeData theme) {
    double totalReturn = 0;
    int wonBets = 0;
    int settledBets = 0;

    for (var bet in _bets) {
      if (bet['status'] == 'Ganhou') {
        totalReturn += bet['amount'] * bet['odd'];
        wonBets++;
        settledBets++;
      } else if (bet['status'] == 'Perdeu') {
        settledBets++;
      }
    }

    double netProfit = totalReturn - _totalSpent;
    double winRate = settledBets > 0 ? (wonBets / settledBets) * 100 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Banca Atual",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${_bank.toStringAsFixed(2)} Kz",
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    "Apostado",
                    "${_totalSpent.toStringAsFixed(0)} Kz",
                    Colors.black87,
                  ),
                  _buildStatItem(
                    "Retorno",
                    "${totalReturn.toStringAsFixed(0)} Kz",
                    Colors.green,
                  ),
                  _buildStatItem(
                    "Lucro",
                    "${netProfit.toStringAsFixed(0)} Kz",
                    netProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  "Win Rate: ${winRate.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
