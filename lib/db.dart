import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';

enum Mode { casual, ranked }

class Database {
  static final String urlPath = "https://csc452-minigame-backend.vercel.app/";
  static final String prefUID = "uid";
  
  static Database instance = Database();

  final headers = {'Content-Type': 'application/json'};
  
  Future<bool> createUser(GameState state) async {
    final url = Uri.parse('${urlPath}users/');
    final data = {
      'NAME': state.name,
      'SCORE': state.score,
      'DATE': null,
      'GAMEOVER': state.gameOver
    };
    final body = jsonEncode(data);

    final res = await http.post(url, body: body, headers: headers);
    final resOK = res.statusCode == 200;
    final dat = jsonDecode(res.body);
    state.uid = dat["insertId"] ?? -1;

    storeLocal(state);

    return resOK;
  }
  Future<bool> updateUser(GameState state) async {
    final url = Uri.parse('${urlPath}users/');
    final body = jsonEncode({
      'SCORE': state.score,
      'DATE': null,
      'GAMEOVER': state.gameOver,
      "ID": state.uid
    });

    final res = await http.put(url, body: body, headers: headers);
    final resOK = res.statusCode == 200;

    return resOK;
  }
  Future<bool> fetchUser(GameState state) async {
    final uid = state.uid;
    final url = Uri.parse('${urlPath}users/$uid');

    final res = await http.get(url, headers: headers);
    final resOK = res.statusCode == 200;
    
    if (resOK) {
      final data = jsonDecode(res.body)[0];
      state.uid = uid;
      state.name = data["NAME"];
      state.mode = Mode.ranked;
      state.score = data["SCORE"];
      state.gameOver = data["GAMEOVER"];
    }

    return resOK;
  }
  Future<bool> removeUser(GameState state) async {
    final url = Uri.parse('${urlPath}users/');
    final body = jsonEncode({ 'ID': state.uid });

    final res = await http.delete(url, body: body, headers: headers);
    final resOK = res.statusCode == 200;

    removeLocal();
  
    return resOK;
  }

  Future<List> leaderboard() async {
    List list = [];
    
    final url = Uri.parse('${urlPath}leaderboard/');
    
    final res = await http.get(url, headers: headers);
    final resOK = res.statusCode == 200;

    if (resOK) {
      final data = jsonDecode(res.body);
      list.addAll(data);
    }

    return list;
  }

  Future<bool> hasLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    return prefs.containsKey(prefUID);
  }
  void storeLocal(GameState state) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(prefUID, state.uid);
  }
  Future<bool> fetchLocal(GameState state) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    if (prefs.containsKey(prefUID)) {
      state.uid = prefs.getInt(prefUID)!;
      print("Saved Session: ${state.uid}");
      return fetchUser(state);
    }

    return false;
  }
  void removeLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefUID)) {
      prefs.remove(prefUID);
    }
  }

  Database() {
    SharedPreferences.getInstance().then((value) => value.reload());
    }
}

class GameState {
  int uid = -1;
  String name = "";
  Mode mode = Mode.casual;
  int score = 0;
  bool gameOver = false;
  Game game = Game.idle;

  @override
  String toString() {
    return "uid: $uid, name: $name, mode: $mode, score: $score, gameOver: $gameOver, game: $game";
  }
}