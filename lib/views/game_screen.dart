import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';

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
    
    // Cambios del controlador (Timer, Puntaje, etc.)
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
        title: const Text('Juego de Memoria'),
        backgroundColor: const Color(0xFF422159),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- TABLERO DE ESTADÍSTICAS ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: const Color(0xFF213f5a).withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Mostramos el Tiempo Restante
                _buildStatItem(
                  "TIEMPO", 
                  _formatTime(_controller.secondsRemaining), 
                  _controller.secondsRemaining < 10 
                  ? Colors.red 
                  : const Color(0xFF40a490)
                ),
                // Mostramos el Puntaje Actual
                _buildStatItem(
                  "PUNTAJE", 
                  "${_controller.score}", 
                  const Color(0xFF422159)
                ),
                // Mostramos el Récord (Persistencia)
                _buildStatItem(
                  "RÉCORD", 
                  "${_controller.highScore}", 
                  const Color.fromARGB(255, 245, 182, 105)
                ),
              ],
            ),
          ),
          
          // --- GRID DE CARTAS ---
          //El bloque Expand fue hecho con Gemini para lograr que todas las cartas 
          //se mostraran sin tener que hacer scroll en la pantalla
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double anchoMaximoTablero = constraints.maxWidth > 500 ? 500 : constraints.maxWidth;
                double altoDisponible = constraints.maxHeight;
                double altoFicha = (altoDisponible / 6) - 6; 
                double anchoFicha = (anchoMaximoTablero / 6) - 6;

                return Center(
                  child: SizedBox(
                    width: anchoMaximoTablero, // Forzamos a que el tablero no sea más ancho que esto
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(), // PROHIBIDO EL SCROLL
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: anchoFicha / altoFicha, // La magia para que quepa verticalmente
                        ),
                        itemCount: _controller.cards.length,
                        itemBuilder: (context, index) {
                          final card = _controller.cards[index];
                          final bool isFaceUp = _controller.cards[index].isMatched || _controller.selectedIndices.contains(index);

                          return GestureDetector(
                            onTap: () {
                              // Aquí llama a tu función de tap del controlador
                              _controller.onCardTap(index);
                              setState(() {}); // Refrescamos para ver el cambio
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isFaceUp 
                                    ? const Color.fromARGB(255, 255, 255, 255) 
                                    : const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _controller.cards[index].isMatched ? const Color(0xFF357c8a) : Colors.blueAccent,
                                  width: 2.5,
                                ),
                              ),
                              child: Center(
                                child: Stack( // Usamos un Stack para poner el '?' y el emoji en el mismo sitio
                                  alignment: Alignment.center,
                                  children: [
                                    // 1. El signo de pregunta (se ve cuando la carta está cerrada)
                                    if (!isFaceUp)
                                      const Text(
                                        '?',
                                        style: TextStyle(fontSize: 24, color: Colors.blueAccent),
                                      ),
                                    
                                    // 2. El emoji (Ya está cargado pero invisible si isFaceUp es false)
                                    Opacity(
                                      opacity: isFaceUp ? 1.0 : 0.0,
                                      child: Text(
                                        card.content,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.black, // Color para cuando se vea el emoji
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
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