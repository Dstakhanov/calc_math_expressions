import 'dart:convert';
import 'dart:io';
import 'parsing_engine.dart';

void main(List<String> arguments) {
  print("\nEnter a mathematical expression, please");

  while (true) {
    String? expr = stdin.readLineSync(encoding: Encoding.getByName("utf-8")!);
    if (expr != null && expr != "exit") {
      Scanner sc = Scanner(expr);
      List<String> constants = sc.constScan();
      Map<String, String> constMap = {};
      for (String c in constants) {
        print("\nEnter any $c value, please");
        String? constValue =
            stdin.readLineSync(encoding: Encoding.getByName("utf-8")!);
        constMap[c.toString()] = constValue ?? "0";
      }
      List<ScannedToken> scanExp = sc.scan(constMap);
      Parser parser = Parser(scanExp);
      List<ScannedToken> parsed = parser.parse();
      print(sc.evaluate(parsed));
      print("""
        \nEnter next mathematical expression, please 
        \nEnter exit for quitting""");
    } else {
      break;
    }
  }
}
