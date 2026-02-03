import 'package:flutter/material.dart';
import '../models/game_card.dart';
import '../controllers/game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // variables de estado
  int _attempts = 0;
  int _matchesFound = 0;
  final GameController _controller = GameController();
  late List<GameCard> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _controller.generateCards();
  }

  // lógica de reinicio
  void _resetGame() {
    setState(() {
      _attempts = 0;
      _matchesFound = 0;
      _cards = _controller.generateCards();
      _controller.selectedIndices.clear();
      _controller.isProcessing = false;
    });
  }

  // mensaje de victoria
  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Misión Cumplida! 🚀'),
        content: Text('Completaste el mapa estelar con $_attempts errores.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Jugar de nuevo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Unimet 6x6'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // tablero de puntaje
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.blueGrey.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("ERRORES", _attempts.toString(), Colors.orange),
                _buildStatItem("PAREJAS", "$_matchesFound / 18", Colors.green),
              ],
            ),
          ),
          
          // grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    // lógca de interacción
                    onTap: () async {
                      if (_controller.isProcessing || _cards[index].isFaceUp || _cards[index].isMatched) {
                        return;
                      }

                      setState(() {
                        _cards[index].isFaceUp = true;
                        _controller.selectedIndices.add(index);
                      });

                      if (_controller.selectedIndices.length == 2) {
                        _controller.isProcessing = true;
                        
                        int first = _controller.selectedIndices[0];
                        int second = _controller.selectedIndices[1];

                        if (_controller.checkMatch(_cards, first, second)) {
                          setState(() {
                            _matchesFound++;
                            _controller.selectedIndices.clear();
                            _controller.isProcessing = false;
                          });
                          if (_matchesFound == 18) _showVictoryDialog();
                        } else {
                          await Future.delayed(const Duration(seconds: 1));
                          if (mounted) {
                            setState(() {
                              _attempts++;
                              _cards[first].isFaceUp = false;
                              _cards[second].isFaceUp = false;
                              _controller.selectedIndices.clear();
                              _controller.isProcessing = false;
                            });
                          }
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _cards[index].isFaceUp || _cards[index].isMatched 
                            ? Colors.white 
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _cards[index].isMatched ? Colors.green : Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _cards[index].isFaceUp || _cards[index].isMatched 
                              ? _cards[index].content 
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            color: _cards[index].isFaceUp ? Colors.black : Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}