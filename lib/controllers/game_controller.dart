import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_card.dart';

class GameController {
  // --- ESTADO DEL JUEGO ---
  List<GameCard> cards = [];
  List<int> selectedIndices = []; // Para saber qué cartas tocó
  bool isProcessing = false;      // Para bloquear el tablero
  bool isGameOver = false;
  int score = 0;

  // --- NUEVOS REQUERIMIENTOS: TIEMPO Y PERSISTENCIA ---
  Timer? _timer;
  int secondsRemaining = 180; // 3 minutos
  int highScore = 0;
  
  // Callback para notificar a la UI (GameScreen) que algo cambió
  Function? onStateChanged;

  final List<String> _cardContents = [
    '🚀', '👩‍🚀', '🪐', '☄️', '🛸', '🌌', '☀️', '🌙', '⭐', '🔭', '🛰️', '👽', '🌑', '🌎', '💥', '🧪', '🤖', '🔋',
  ];

  // --- INICIALIZACIÓN ---
  // Este método arranca todo: carga el récord, resetea variables y genera cartas
  void initializeGame() {
    _loadHighScore(); // Carga la persistencia
    resetGame();
  }

  void resetGame() {
    score = 0;
    isGameOver = false;
    secondsRemaining = 180; 
    selectedIndices.clear();
    isProcessing = false;
    
    _generateCards(); // Genera las cartas internamente
    _startTimer();    // Arranca el reloj
    _notifyUI();
  }

  // --- LÓGICA DE CARTAS (Tu código original adaptado) ---
  void _generateCards() {
    cards = [];
    int id = 0;
    for (String content in _cardContents) {
      cards.add(GameCard(id: id++, content: content));
      cards.add(GameCard(id: id++, content: content));
    }
    cards.shuffle();
  }

  // Método para manejar el toque de una carta
  void onCardTap(int index) {
    if (isProcessing || isGameOver || cards[index].isMatched || selectedIndices.contains(index)) {
      return; 
    }

    selectedIndices.add(index);
    _notifyUI(); // Actualizar para mostrar la carta volteada

    if (selectedIndices.length == 2) {
      isProcessing = true;
      // Pequeño delay para que el usuario vea la segunda carta
      Timer(const Duration(milliseconds: 800), () {
        _checkMatch();
        isProcessing = false;
        _notifyUI();
      });
    }
  }

  void _checkMatch() {
    int index1 = selectedIndices[0];
    int index2 = selectedIndices[1];

    if (cards[index1].content == cards[index2].content) {
      // ¡Es un par!
      cards[index1].isMatched = true;
      cards[index2].isMatched = true;
      score += 100; // Sumamos puntos
      
      // Verificar si ganó (todas las cartas están matched)
      if (cards.every((card) => card.isMatched)) {
        _onGameWin();
      }
    } 
    // Limpiamos la selección haya match o no
    selectedIndices.clear();
  }

  // --- LÓGICA DEL TEMPORIZADOR ---
  void _startTimer() {
    _timer?.cancel(); // Cancelar timer previo si existe
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0 && !isGameOver) {
        secondsRemaining--;
        _notifyUI();
      } else {
        _stopTimer();
        if (!isGameOver) {
          // Si el tiempo llega a 0 y no ha ganado, es Game Over
          isGameOver = true;
          _checkHighScore(); 
          _notifyUI();
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _onGameWin() {
    isGameOver = true;
    _stopTimer();
    // Bonificación por tiempo: 10 puntos por cada segundo sobrante
    score += (secondsRemaining * 10);
    _checkHighScore();
  }

  // --- LÓGICA DE PERSISTENCIA ---
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('high_score') ?? 0;
    _notifyUI();
  }

  Future<void> _checkHighScore() async {
    if (score > highScore) {
      highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('high_score', highScore);
    }
  }

  // --- UTILIDADES ---
  void _notifyUI() {
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  void dispose() {
    _stopTimer();
  }
}