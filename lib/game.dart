import 'dart:math';

enum Game { idle, quickMath, pictureMatch, gameOver }
enum MathOperand { plus, minus, multiply }

class QuickMath {
  int question1 = -1;
  int question2 = -1;
  MathOperand operand = MathOperand.plus;
  String questionString = "";
  int answer = 0;
  Set<int> options = {};
  
  void generate() {
    question1 = Random().nextInt(20);
    question2 = Random().nextInt(20);
    operand = MathOperand.values[Random().nextInt(MathOperand.values.length)];
    answer = calculate(question1, question2, operand);

    questionString = "$question1 " + [ "+", "-", "×" ][operand.index] + " $question2";

    List<int> optionsList = [ answer ];
   
    while (optionsList.length < 5) {
      int num = calculate(Random().nextInt(20), Random().nextInt(20), MathOperand.values[Random().nextInt(MathOperand.values.length)]);
      if (!optionsList.contains(num)) {
        optionsList.add(num);
      }
    }

    optionsList.shuffle();
    options = optionsList.toSet();
  }

  int calculate(int n1, int n2, MathOperand op) {
    switch (op) {
      case MathOperand.plus:
        return n1 + n2;
      case MathOperand.minus:
        return n1 - n2;
      case MathOperand.multiply:
        return n1 * n2;
    }

    return 0;
  }
}
class PictureMatch {
  final Set<String> source = { "▣", "⁜", "※", "⌂" };

  List<String> options = [];
  Set<int> selected = {};
  int selectedA = -1;
  int tries = 10;

  void generate() {
    options = source.toList();
    options += options;
    options.shuffle();
  }
}
