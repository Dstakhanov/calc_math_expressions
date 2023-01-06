import 'dart:core';
import 'dart:math';

enum TokenType { ADD, SUB, MUL, DIV, POW, LPAR, RPAR, VALUE }

TokenType fromString(String s) {
  switch (s) {
    case "+":
      return TokenType.ADD;
    case "-":
      return TokenType.SUB;
    case "*":
      return TokenType.MUL;
    case "/":
      return TokenType.DIV;
    case "^":
      return TokenType.POW;
    case "(":
      return TokenType.LPAR;
    case ")":
      return TokenType.RPAR;
    default:
      return TokenType.VALUE;
  }
}

class ScannedToken {
  late String _expressionPiece;
  late TokenType _type;

  ScannedToken(String exp, TokenType type) {
    _expressionPiece = exp;
    _type = type;
  }

  @override
  String toString() {
    return "(Expr:$_expressionPiece, Token:$_type)";
  }

  TokenType type() {
    return _type;
  }

  String expression() {
    return _expressionPiece;
  }
}

class Scanner {
  String _expression = "";

  Scanner(String expr) {
    _expression = expr;
  }

  List<String> constScan() {
    List<String> scannedConst = [];
    String symb = "abcdefghijklmnopqrstuvwxyz";
    String currentConst = "";
    for (String c in _expression.split('')) {
      if (symb.contains(c)) {
        currentConst += c;
      } else {
        if (currentConst.isNotEmpty) {
          scannedConst.add(currentConst);
          currentConst = "";
        }
      }
    }

    return scannedConst;
  }

  List<ScannedToken> scan(Map<String, String> constMap) {
    String value = "";
    List<ScannedToken> scannedExpr = [];
    _expression = _expression.replaceAll(" ", "");
    for (var item in constMap.entries) {
      _expression = _expression.replaceAll(item.key, item.value);
    }
    for (String c in _expression.split('')) {
      TokenType type = fromString(c);
      if (type != TokenType.VALUE) {
        if (value.isNotEmpty) {
          //Add the full value TOKEN
          ScannedToken st = ScannedToken(value.toString(), TokenType.VALUE);
          scannedExpr.add(st);
        }
        value = c;
        ScannedToken st = ScannedToken(value.toString(), type);
        scannedExpr.add(st);
        value = "";
      } else {
        value += c;
      }
    }
    if (value.isNotEmpty) {
      //Add the full value TOKEN
      ScannedToken st = ScannedToken(value.toString(), TokenType.VALUE);
      scannedExpr.add(st);
    }

    return scannedExpr;
  }

  double evaluate(List<ScannedToken> tokenizedExpression) {
    if (tokenizedExpression.length == 1) {
      return double.parse(tokenizedExpression[0].expression());
    }
    List<ScannedToken> simpleExpr = [];

    int idx = tokenizedExpression
        .map((ScannedToken st) => st.type())
        .toList()
        .lastIndexOf(TokenType.LPAR);
    int matchingRPAR = -1;
    if (idx >= 0) {
      for (int i = idx + 1; i < tokenizedExpression.length; i++) {
        ScannedToken curr = tokenizedExpression[i];
        if (curr.type() == TokenType.RPAR) {
          matchingRPAR = i;
          break;
        } else {
          simpleExpr.add(tokenizedExpression[i]);
        }
      }
    } else {
      simpleExpr.addAll(tokenizedExpression);
      return evaluateSimpleExpression(tokenizedExpression);
    }

    double value = evaluateSimpleExpression(simpleExpr);
    List<ScannedToken> partiallyEvaluatedExpression = [];
    for (int i = 0; i < idx; i++) {
      partiallyEvaluatedExpression.add(tokenizedExpression[i]);
    }
    partiallyEvaluatedExpression
        .add(ScannedToken(value.toString(), TokenType.VALUE));
    for (int i = matchingRPAR + 1; i < tokenizedExpression.length; i++) {
      partiallyEvaluatedExpression.add(tokenizedExpression[i]);
    }

    return evaluate(partiallyEvaluatedExpression);
  }

  double evaluateSimpleExpression(List<ScannedToken> expression) {
    if (expression.length == 1) {
      return double.parse(expression[0].expression());
    } else {
      List<ScannedToken> newExpression = [];
      int idx = expression
          .map((ScannedToken st) => st.type())
          .toList()
          .indexOf(TokenType.POW);
      if (idx != -1) {
        double base = double.parse(expression[idx - 1].expression());
        double exp = double.parse(expression[idx + 1].expression());
        double ans = pow(base, exp).toDouble();
        for (int i = 0; i < idx - 1; i++) {
          newExpression.add(expression[i]);
        }
        newExpression.add(ScannedToken(ans.toString(), TokenType.VALUE));
        for (int i = idx + 2; i < expression.length; i++) {
          newExpression.add(expression[i]);
        }
        return evaluateSimpleExpression(newExpression);
      } else {
        int mulIdx = expression
            .map((ScannedToken st) => st.type())
            .toList()
            .indexOf(TokenType.MUL);
        int divIdx = expression
            .map((ScannedToken st) => st.type())
            .toList()
            .indexOf(TokenType.DIV);
        int computationIdx = (mulIdx >= 0 && divIdx >= 0)
            ? min(mulIdx, divIdx)
            : max(mulIdx, divIdx);
        if (computationIdx != -1) {
          double left =
              double.parse(expression[computationIdx - 1].expression());
          double right =
              double.parse(expression[computationIdx + 1].expression());
          double ans =
              computationIdx == mulIdx ? left * right : left / right * 1.0;
          for (int i = 0; i < computationIdx - 1; i++) {
            newExpression.add(expression[i]);
          }
          newExpression.add(ScannedToken(ans.toString(), TokenType.VALUE));
          for (int i = computationIdx + 2; i < expression.length; i++) {
            newExpression.add(expression[i]);
          }
          return evaluateSimpleExpression(newExpression);
        } else {
          int addIdx = expression
              .map((ScannedToken st) => st.type())
              .toList()
              .indexOf(TokenType.ADD);
          int subIdx = expression
              .map((ScannedToken st) => st.type())
              .toList()
              .indexOf(TokenType.SUB);
          int computationIdx2 = (addIdx >= 0 && subIdx >= 0)
              ? min(addIdx, subIdx)
              : max(addIdx, subIdx);
          if (computationIdx2 != -1) {
            double left =
                double.parse(expression[computationIdx2 - 1].expression());
            double right =
                double.parse(expression[computationIdx2 + 1].expression());
            double ans =
                computationIdx2 == addIdx ? left + right : (left - right) * 1.0;
            for (int i = 0; i < computationIdx2 - 1; i++) {
              newExpression.add(expression[i]);
            }
            newExpression.add(ScannedToken(ans.toString(), TokenType.VALUE));
            for (int i = computationIdx2 + 2; i < expression.length; i++) {
              newExpression.add(expression[i]);
            }
            return evaluateSimpleExpression(newExpression);
          }
        }
      }
    }
    return -1.0;
  }
}

class Parser {
  List<ScannedToken> _expression = [];

  Parser(List<ScannedToken> expression) {
    _expression = expression;
  }

  List<ScannedToken> parse() {
    late TokenType? prev;
    late TokenType? curr;
    late TokenType? next;

    List<ScannedToken> properlyParsedExpression = [];

    List<TokenType> types =
        _expression.map((ScannedToken st) => st.type()).toList();
    List<int> indexes = [];
    List<ScannedToken> negativeValues = [];

    for (int i = 0; i < types.length - 1; i++) {
      prev = i == 0 ? null : types[i - 1];
      curr = types[i];
      next = types[i + 1];
      if (prev == null && curr == TokenType.SUB && next == TokenType.VALUE) {
        ScannedToken negativeValue = ScannedToken(
            (-1 * double.parse(_expression[i + 1].expression())).toString(),
            TokenType.VALUE);
        indexes.add(i);
        negativeValues.add(negativeValue);
      } else if (prev == TokenType.LPAR &&
          curr == TokenType.SUB &&
          next == TokenType.VALUE) {
        ScannedToken negativeValue = ScannedToken(
            (-1 * double.parse(_expression[i + 1].expression())).toString(),
            TokenType.VALUE);
        indexes.add(i);
        negativeValues.add(negativeValue);
      }
    }

    int maxIterations = _expression.length;
    int i = 0;
    int j = 0;
    while (i < maxIterations) {
      if (indexes.contains(i) && j < negativeValues.length) {
        properlyParsedExpression.add(negativeValues[j]);
        j++;
        i++;
      } else {
        properlyParsedExpression.add(_expression[i]);
      }
      i++;
    }
    return properlyParsedExpression;
  }
}
