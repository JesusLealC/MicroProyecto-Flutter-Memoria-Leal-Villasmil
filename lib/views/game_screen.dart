import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
// Asegúrate de que la ruta al modelo sea correcta según tu proyecto
import '../models/game_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Instanciamos el controlador que creamos en el paso anterior
  final GameController _controller = GameController();
  
  // Variable para evitar que el diálogo de victoria/derrota se abra muchas veces
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    
    // Escuchamos los cambios del controlador (Timer, Puntaje, etc.)
    _controller.onStateChanged = () {
      if (mounted) {
        setState(() {
          // Si el juego terminó y no hemos mostrado el diálogo, lo mostramos
          if (_controller.isGameOver && !_isDialogShown) {
            _showEndGameDialog();
            _isDialogShown = true;
          }
        });
      }
    };
    
    // Iniciamos el juego (Timer, Carga de Récord, Cartas)
    _controller.initializeGame();
  }

  @override
  void dispose() {
    _controller.dispose(); // Detiene el timer para evitar errores
    super.dispose();
  }

  // Helper para mostrar el tiempo en formato mm:ss
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _restartGame() {
    setState(() {
      _isDialogShown = false;
      _controller.resetGame();
    });
  }

  // Diálogo unificado para Fin de Juego (Ganar o Perder por tiempo)
  void _showEndGameDialog() {
    bool isWin = _controller.cards.every((c) => c.isMatched);
    String title = isWin ? '¡Misión Cumplida! 🚀' : '¡Tiempo Agotado! ⏳';
    String content = isWin 
        ? 'Puntaje final: ${_controller.score}. ¡Nuevo Récord!' 
        : 'Se acabó el oxígeno. Inténtalo de nuevo.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
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
          // --- TABLERO DE ESTADÍSTICAS ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.blueGrey.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Mostramos el Tiempo Restante
                _buildStatItem(
                  "TIEMPO", 
                  _formatTime(_controller.secondsRemaining), 
                  _controller.secondsRemaining < 10 ? Colors.red : Colors.blue
                ),
                // Mostramos el Puntaje Actual
                _buildStatItem(
                  "PUNTAJE", 
                  "${_controller.score}", 
                  Colors.green
                ),
                // Mostramos el Récord (Persistencia)
                _buildStatItem(
                  "RÉCORD", 
                  "${_controller.highScore}", 
                  Colors.orange
                ),
              ],
            ),
          ),
          
          // --- GRID DE CARTAS ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _controller.cards.length,
                itemBuilder: (context, index) {
                  final card = _controller.cards[index];
                  // Una carta se muestra si ya hizo match o si está seleccionada temporalmente
                  final bool isFaceUp = card.isMatched || _controller.selectedIndices.contains(index);

                  return GestureDetector(
                    onTap: () {
                      // Toda la lógica compleja ahora está en el controlador
                      _controller.onCardTap(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isFaceUp 
                            ? Colors.white 
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: card.isMatched ? Colors.green : Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isFaceUp ? card.content : '?',
                          style: TextStyle(
                            fontSize: 20,
                            color: isFaceUp ? Colors.black : Colors.blueAccent,
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