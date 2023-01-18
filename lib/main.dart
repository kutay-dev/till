import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'dart:ui';
import 'package:get_storage/get_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() async {
  await GetStorage.init();
  runApp(const App());
}

final box = GetStorage();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

void confirmDelete(
    BuildContext context, num id, dynamic deleteCounter, String title) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 2,
          sigmaY: 2,
        ),
        child: AlertDialog(
          title: Text(
            (title.isEmpty
                ? "Delete unnamed counter?"
                : 'Delete "$title" counter?'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent),
              child: const Text(
                "No",
                style: TextStyle(color: Colors.black45),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                for (int i = 0; i < counterObj.length; i++) {
                  if (counterObj[i]["id"] == id) {
                    deleteCounter(i);
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent),
              child: const Text(
                "Yes",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    },
  );
}

List counterObj = box.read("counterObj") ?? [];

class _MainState extends State<Main> {
  List counterCards = [];

  final TextEditingController titleController = TextEditingController();

  late DateTime date;
  late String dateStr;

  @override
  void initState() {
    getCounterCards();
    super.initState();
  }

  void getCounterCards() {
    counterCards.clear();
    for (int i = 0; i < counterObj.length; i++) {
      counterCards.add(CounterCard(
        title: counterObj[i]["title"],
        id: counterObj[i]["id"],
        firstLeft: counterObj[i]["leftt"],
        date: counterObj[i]["date"],
        done: counterObj[i]["done"],
        deleteCounter: deleteCounter,
      ));
    }
  }

  void deleteCounter(i) {
    counterObj.removeAt(i);
    box.write("counterObj", counterObj);
    getCounterCards();
    setState(() {});
  }

  void addCounterCard() {
    int id = Random().nextInt(1000000);
    DateTime now = DateTime.now();
    double left = date.difference(now).inSeconds.toDouble();

    counterObj.add({
      "title": titleController.text,
      "id": id,
      "leftt": left,
      "date": dateStr,
      "done": false,
    });

    box.write("counterObj", counterObj);
    getCounterCards();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.black12,
        onPressed: () {},
        child: IconButton(
          icon: const Icon(
            Icons.add,
            size: 30,
          ),
          onPressed: () {
            showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (BuildContext context) {
                return SizedBox(
                  height: 600,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          maxLength: 12,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: "TITLE",
                            hintStyle: TextStyle(
                                color: Colors.black26,
                                fontWeight: FontWeight.bold),
                          ),
                          textAlign: TextAlign.center,
                          controller: titleController,
                        ),
                      ),
                      Expanded(
                        child: CupertinoDatePicker(
                          initialDateTime: DateTime.now(),
                          onDateTimeChanged: (value) {
                            date = value;
                          },
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blueAccent, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            DateTime now = DateTime.now();
                            dateStr = "$date";
                            Duration diff = now.difference(date);

                            if (diff.isNegative) {
                              Navigator.of(context).pop();
                              addCounterCard();
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text("Add Counter"),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: (counterCards.isNotEmpty
                ? ListView.builder(
                    itemCount: counterCards.length,
                    itemBuilder: ((context, index) {
                      return counterCards[index];
                    }),
                  )
                : const Center(
                    child: Text(
                      "You haven't set any counter yet",
                      style: TextStyle(color: Colors.black45),
                    ),
                  )),
          ),
        ],
      ),
    );
  }
}

class CounterCard extends StatefulWidget {
  CounterCard({
    Key? key,
    required this.title,
    required this.id,
    required this.firstLeft,
    required this.date,
    required this.done,
    required this.deleteCounter,
  }) : super(key: key);

  final dynamic deleteCounter;
  final int id;
  final double firstLeft;
  final String title;
  final String date;

  bool done;

  @override
  State<CounterCard> createState() => _CounterCardState();
}

class _CounterCardState extends State<CounterCard> {
  late num daysLeft;
  late num hoursLeft;
  late num minsLeft;
  late num left;

  late double perc;

  @override
  void initState() {
    getDifferece();
    super.initState();
  }

  void getDifferece() async {
    for (int i = 0; i < counterObj.length; i++) {
      if (counterObj[i]["id"] == widget.id) {
        widget.done = counterObj[i]["done"];
      }
    }

    while (true) {
      DateTime now = DateTime.now();
      DateTime leftInSecs = DateTime.parse(widget.date);
      left = leftInSecs.difference(now).inSeconds.toDouble();
      perc = ((left - widget.firstLeft) / widget.firstLeft) * 100;
      if (left <= 0) {
        perc = 0;
        for (int i = 0; i < counterObj.length; i++) {
          if (counterObj[i]["id"] == widget.id) {
            counterObj[i]["done"] = true;
            widget.done = true;
          }
        }
        setState(() {});
        break;
      }
      if (!widget.done) {
        daysLeft = left / 86400;
        daysLeft = daysLeft.floor();
        left -= daysLeft * 86400;

        hoursLeft = left / 3600;
        hoursLeft = hoursLeft.floor();
        left -= hoursLeft * 3600;

        minsLeft = left / 60;
        minsLeft = minsLeft.floor();
        left -= minsLeft * 60;

        await Future.delayed(const Duration(seconds: 1));

        for (int i = 0; i < counterObj.length; i++) {
          if (counterObj[i]["id"] == widget.id) {
            left -= 1;
            box.write("counterObj", counterObj);
          }
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      child: Container(
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.blueAccent,
                Colors.purpleAccent,
              ],
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
            color: (!widget.done) ? Colors.tealAccent : Colors.teal),
        height: 120,
        child: Stack(
          children: [
            Row(
              children: [
                const SizedBox(width: 20),
                CircularPercentIndicator(
                  radius: 35,
                  lineWidth: 5,
                  percent: (100 + perc) / 100,
                  progressColor: Colors.white,
                  backgroundColor: Colors.white10,
                  circularStrokeCap: CircularStrokeCap.round,
                  center: (widget.done
                      ? const Icon(
                          Icons.check,
                          size: 27,
                          color: Colors.white,
                        )
                      : Text(
                          "${(100 + perc).toStringAsFixed(0)}%",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      widget.title.toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    (!widget.done
                        ? Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      "D: $daysLeft",
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "H: $hoursLeft",
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      "M: $minsLeft",
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "S: ${left.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox()),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white38,
                ),
                onPressed: () {
                  confirmDelete(
                      context, widget.id, widget.deleteCounter, widget.title);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
