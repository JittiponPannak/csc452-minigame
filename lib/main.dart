import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'game.dart';
import 'db.dart';

Database db = Database.instance;
GameState? state;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Minigame', home: MainPage(), routes: {});
  }
}

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  TextEditingController usernameController = TextEditingController(text: "");
  List<Widget> leaderboard = [];
  bool playWaiting = false;

  void reloadLeaderboard() {
    db.leaderboard().then((data) {
      List<Text> widgets = [];

      for (var element in data) {
        widgets.add(
          Text(
            "${element["NAME"]} | ${element["SCORE"]}",
            style: TextStyle(fontSize: 18),
          ),
        );
      }

      setState(() {
        leaderboard = widgets;
      });
    });
  }
  /*
  void tryContinuePrev() {
    db.hasLocal().then((bool existed) {
      GameState _state = GameState();
      db.fetchLocal(_state).then((valid) {
        if (valid) {
          play(Mode.ranked, _state, _state.name);
        }
      });
    });
  }
  */

  void play(Mode mode, GameState? _state, String? username) async {
    if (playWaiting) {
      return;
    }

    username = username ?? usernameController.text;

    if (username.isNotEmpty) {
      state = _state ?? GameState();

      state!.mode = mode;
      state!.name = username;

      if (mode == Mode.ranked) {
        playWaiting = true;
        final ok = await db.createUser(state!);
        playWaiting = false;

        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Can't Connect to Server!", style: TextStyle(fontSize: 24),), backgroundColor: Colors.red));
          return;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GamePage()),
      ).then((value) {
        if (state!.mode == Mode.ranked) {
          if (state!.gameOver) {
            db.removeLocal();
            if (state!.score <= 0) {
              db.removeUser(state!);
            }
          }
        }

        reloadLeaderboard();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The Username cannot be empty! (￣_￣|||)", style: TextStyle(fontSize: 24),), backgroundColor: Colors.red));
    }
  }

  @override
  void initState() {
    super.initState();
    reloadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              [
                Text(
                  "▶     THE MINIGAME     ◀",
                  style: TextStyle(fontSize: 48),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50.0),
                Text("=========   GROUP   =========\n"),
                Text("6606405 Jittipon Pannak"),
                Text("6606250 Phoorepath Phooraya"),
                Text("6606502 Thannatee Tepkumgan"),
                Text("\n============================="),
                SizedBox(height: 25.0),
                SizedBox(height: 25.0),
                Text("▼     Username     ▼"),
                SizedBox(
                  width: 250.0,
                  child: TextFormField(
                    controller: usernameController,
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
                Divider(color: Colors.transparent, height: 50.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => {play(Mode.casual, null, null)},
                      child: Text("Casual", style: TextStyle(fontSize: 24),),
                    ),
                    SizedBox(width: 12.5),
                    ElevatedButton(
                      onPressed: () => {play(Mode.ranked, null, null)},
                      child: Text("Ranked", style: TextStyle(fontSize: 24),),
                    ),
                  ],
                ),
                SizedBox(height: 50.0),
                Text("! NOTE !"),
                Text("Casual means a local playthrough!"),
                Text("Ranked means your score will be on leaderboard!"),
                SizedBox(height: 25.0),
                SizedBox(height: 25.0),
                Text("Leaderboard", style: TextStyle(fontSize: 32)),
                SizedBox(height: 12.5),
              ] +
              leaderboard,
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return GamePageState();
  }
}

class GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    setState(() {
      if (state!.mode == Mode.ranked) {
        if (state!.score > 0) {
          db.updateUser(state!);
        }
      }
    });

    nextScene() => {
      setState(() {
        state!.game =
            [Game.quickMath, Game.pictureMatch][Random().nextInt(
              Game.values.length - 2,
            )];

        switch (state!.game) {
          case Game.pictureMatch:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => QuickMathPage()),
            );
            return;
          case Game.quickMath:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PictureMatchPage()),
            );
            return;
          default:
            break;
        }
      }),
    };

    returnMain() => {
      setState(() {
        Navigator.pop(context);
      }),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${state!.mode == Mode.ranked ? "Ranked" : "Casual"} / Game",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Scaffold(
          body: Center(
            child:
                state!.gameOver
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          ["（；´д｀）ゞ", "(´。＿。｀)", "(┬┬﹏┬┬)", "X﹏X"][Random()
                              .nextInt(4)],
                          style: TextStyle(fontSize: 48),
                        ),
                        Text(
                          "Final Score : ${state!.score}",
                          style: TextStyle(fontSize: 24),
                        ),
                        /*
                        SizedBox(height: 10.0),
                        ElevatedButton(
                          onPressed: returnMain,
                          child: Text("Return", style: TextStyle(fontSize: 24),),
                        ),
                        */
                      ],
                    )
                    : Column(
                      children: [
                        SizedBox(height: 50.0),
                        Text(
                          [
                            "(●'◡'●)",
                            "☆*: .｡. o(≧▽≦)o .｡.:*☆",
                            "^_^",
                            "( •̀ ω •́ )✧",
                            "ㄟ(≧◇≦)ㄏ",
                          ][Random().nextInt(5)],
                          style: TextStyle(fontSize: 48),
                        ),
                        SizedBox(height: 50.0),
                        Text(
                          "Score : ${state!.score}",
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(height: 25.0),
                        ElevatedButton(
                          onPressed: nextScene,
                          child: Text(
                            "Next Scene",
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class QuickMathPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return QuickMathPageState();
  }
}

class QuickMathPageState extends State<QuickMathPage> {
  Timer? timer;
  int timeout = 10;
  QuickMath? data;

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  void success() {
    setState(() {
      state!.score += 10;
      state!.game = Game.idle;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GamePage()),
      );
    });
  }

  void failed() {
    setState(() {
      state!.gameOver = true;
      state!.game = Game.idle;

      db.removeLocal();
      if (state!.score <= 0) {
        db.removeUser(state!);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GamePage()),
      );
    });
  }

  @override
  void initState() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timeout--;
        if (timeout <= 0) {
          state!.gameOver = true;
          state!.game = Game.idle;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GamePage()),
          );
        }
      });
    });
    data = QuickMath();
    data!.generate();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];
    for (int number in data!.options) {
      buttons.add(
        Column(
          children: [
            SizedBox(height: 5),
            ElevatedButton(
              onPressed: () => {number == data!.answer ? success() : failed()},
              child: Text("$number", style: TextStyle(fontSize: 24)),
            ),
            SizedBox(height: 5),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${state!.mode == Mode.ranked ? "Ranked" : "Casual"} / Quick Math",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          children: [
            Text("Time Left: $timeout", style: TextStyle(fontSize: 48)),
            Text("Name: ${state!.name}", style: TextStyle(fontSize: 16)),
            Text("Score: ${state!.score}", style: TextStyle(fontSize: 24)),
            SizedBox(height: 25),
            Text(data!.questionString),
            SizedBox(height: 25),
            Column(children: buttons),
          ],
        ),
      ),
    );
  }
}

class PictureMatchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PictureMatchPageState();
  }
}

class PictureMatchPageState extends State<PictureMatchPage> {
  Timer? timer;
  int timeout = 60;
  PictureMatch? data;

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  @override
  void initState() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timeout--;
        if (timeout <= 0) {
          state!.gameOver = true;
          state!.game = Game.idle;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GamePage()),
          );
        }
      });
    });
    data = PictureMatch();
    data!.generate();

    super.initState();
  }

  void success() {
    setState(() {
      state!.score += 10;
      state!.game = Game.idle;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GamePage()),
      );
    });
  }

  void failed() {
    setState(() {
      state!.gameOver = true;
      state!.game = Game.idle;

      db.removeLocal();
      if (state!.score <= 0) {
        db.removeUser(state!);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GamePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    callback(int number) {
      if (data!.selectedA == number || data!.selected.contains(number)) {
        return;
      }
      
      setState(() {

        if (data!.selectedA == -1) {
          data!.selectedA = number;
          return;
        }

        final selectedB = number;
        if (data!.options[data!.selectedA] == data!.options[selectedB]) {
          data!.selected.add(data!.selectedA);
          data!.selected.add(selectedB);
        } else {
          data!.tries--;
        }

        if (data!.tries <= 0) {
          failed();
          return;
        }
        if (data!.selected.length >= data!.options.length) {
          success();
          return;
        }

        data!.selectedA = -1;
      });
    }

    List<Widget> buttons = [];

    for (int i = 0; i < data!.options.length; i++) {
      buttons.add(
        Center(
          child: ElevatedButton(
            onPressed: () => {callback(i)},
            child: Text(
              data!.selected.contains(i) || data!.selectedA == i
                  ? data!.options[i]
                  : " ? ",
              style: TextStyle(fontSize: 48),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${state!.mode == Mode.ranked ? "Ranked" : "Casual"} / Picture Match",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          children: [
            Text("Time Left: $timeout", style: TextStyle(fontSize: 48)),
            Text("Name: ${state!.name}", style: TextStyle(fontSize: 16)),
            Text("Score: ${state!.score}", style: TextStyle(fontSize: 24)),
            SizedBox(height: 25),
            Center(
              child: Row(
                children: buttons,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
            SizedBox(height: 25),
            Text("Tries Left: ${data!.tries}", style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
