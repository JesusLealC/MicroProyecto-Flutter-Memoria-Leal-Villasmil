class GameCard {
  final int id;           // id único para cada carta
  final String content;    // el identificador del ícono
  bool isFaceUp;          // estado actual: arriba o abajo
  bool isMatched;         // si se encontró el par

  GameCard({
    required this.id,
    required this.content,
    this.isFaceUp = false,  // las cartas empiezan hacia abajo
    this.isMatched = false, // las cartas empiezan sin estar "matched"
  });

  // Para voltear las cartas sin afectarlas
  void flip() {
    isFaceUp = !isFaceUp;
  }
}