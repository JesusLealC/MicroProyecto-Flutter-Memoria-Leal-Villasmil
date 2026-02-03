import '../models/game_card.dart';

class GameController {
  List<int> selectedIndices = []; // Para saber qué cartas tocó
  bool isProcessing = false;      // Para bloquear el tablero

  final List<String> _cardContents = [
    '🚀', '👩‍🚀', '🪐', '☄️', '🛸', '🌌', '☀️', '🌙', '⭐', '🔭', '🛰️', '👽', '🌑', '🌎', '💥', '🧪', '🤖', '🔋',
  ];

  List<GameCard> generateCards() {
    List<GameCard> cards = [];
    int id = 0;
    for (String content in _cardContents) {
      cards.add(GameCard(id: id++, content: content));
      cards.add(GameCard(id: id++, content: content));
    }
    cards.shuffle();
    return cards;
  }

  bool checkMatch(List<GameCard> cards, int index1, int index2) {
    if (cards[index1].content == cards[index2].content) {
      cards[index1].isMatched = true;
      cards[index2].isMatched = true;
      return true;
    }
    return false;
  }
}