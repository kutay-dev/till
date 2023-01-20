import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:image_picker/image_picker.dart';

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
        filter: ImageFilter.blur(),
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

dynamic size;

class _MainState extends State<Main> {
  List counterCards = [];

  final TextEditingController titleController = TextEditingController();

  late DateTime date;
  late String dateStr;

  PickedFile? selected;

  Future<void> pickImage() async {
    selected = await ImagePicker().getImage(source: ImageSource.gallery);
  }

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
        getCounterCards: getCounterCards,
        image: counterObj[i]["image"],
      ));
    }
    setState(() {});
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
      "image": selected != null ? selected!.path : "null",
    });

    box.write("counterObj", counterObj);
    getCounterCards();
    selected = null;
    titleController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          BlurFilter(
            radius: 100,
            sigmaX: 10,
            sigmaY: 10,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.all(
                  Radius.circular(200),
                ),
              ),
              width: 60,
              height: 60,
            ),
          ),
          SizedBox(
            width: 60,
            height: 60,
            child: IconButton(
              onPressed: () {
                showModalBottomSheet(
                  constraints: BoxConstraints(maxWidth: size.width / 1.1),
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
                      child: Stack(
                        children: [
                          CupertinoDatePicker(
                            initialDateTime: DateTime.now(),
                            onDateTimeChanged: (value) {
                              date = value;
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.only(bottom: 50),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 170,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blueAccent,
                                    Colors.purpleAccent
                                  ],
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
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Text(
                                  "Add Counter",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          TextField(
                            maxLength: 12,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22),
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: "TITLE",
                              hintStyle: TextStyle(
                                  fontSize: 22,
                                  color: Colors.black26,
                                  fontWeight: FontWeight.bold),
                            ),
                            textAlign: TextAlign.center,
                            controller: titleController,
                          ),
                          Positioned(
                            bottom: 50,
                            right: 50,
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.image,
                                ),
                                onPressed: () => pickImage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              iconSize: 30,
              color: Colors.white,
              splashRadius: 0.1,
            ),
          ),
        ],
      ),
      body: SizedBox(
        child: Expanded(
          child: (counterCards.isNotEmpty
              ? ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) {
                      newIndex--;
                    }
                    final counterCard = counterObj.removeAt(oldIndex);
                    counterObj.insert(newIndex, counterCard);
                    getCounterCards();
                    setState(() {});
                  },
                  children: [
                    const SizedBox(
                      height: 50,
                      key: ValueKey(null),
                    ),
                    for (final counterCard in counterCards)
                      SizedBox(
                        key: ValueKey(counterCard),
                        child: counterCard,
                      ),
                  ],
                )
              : const Center(
                  child: Text(
                    "You haven't set any counter yet",
                    style: TextStyle(color: Colors.black45),
                  ),
                )),
        ),
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
    required this.image,
    required this.getCounterCards,
  }) : super(key: key);

  final dynamic deleteCounter;
  final dynamic getCounterCards;
  final int id;
  final double firstLeft;
  final String title;
  final String date;
  String image;

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

  bool showOptions = false;

  TextEditingController titleController = TextEditingController();

  PickedFile? selected;

  @override
  void initState() {
    titleController.text = widget.title;
    getDifferece();
    super.initState();
  }

  Future<void> pickImage() async {
    selected = await ImagePicker().getImage(source: ImageSource.gallery);
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
        decoration: widget.image == "null"
            ? BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 0), // changes position of shadow
                  ),
                ],
              )
            : null,
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.blueAccent.withOpacity(0.8),
                Colors.purpleAccent.withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              widget.image == "null"
                  ? const SizedBox()
                  : BlurFilter(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 10,
                              offset: const Offset(
                                  0, 0), // changes position of shadow
                            ),
                          ],
                        ),
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(widget.image),
                            fit: BoxFit.cover,
                            colorBlendMode: BlendMode.darken,
                            color: Colors.black12,
                          ),
                        ),
                      ),
                    ),
              !showOptions
                  ? Row(
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
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
                    )
                  : const SizedBox(),
              !showOptions
                  ? Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          showOptions = true;
                          setState(() {});
                        },
                      ),
                    )
                  : const SizedBox(),
              showOptions
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Stack(
                        children: [
                          BlurFilter(child: Container()),
                          SizedBox(
                            width: 250,
                            child: TextField(
                              decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(width: 1, color: Colors.white),
                                ),
                              ),
                              controller: titleController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              onPressed: () {
                                showOptions = false;
                                for (int i = 0; i < counterObj.length; i++) {
                                  if (counterObj[i]["id"] == widget.id) {
                                    counterObj[i]["title"] =
                                        titleController.text;
                                    selected != null
                                        ? counterObj[i]["image"] =
                                            selected!.path
                                        : null;
                                    box.write("counterObj", counterObj);

                                    widget.getCounterCards();
                                  }
                                }
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () {
                                pickImage().then((value) {
                                  setState(() {
                                    widget.image = selected!.path;
                                  });
                                });
                              },
                              icon: const Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: IconButton(
                              onPressed: () {
                                confirmDelete(context, widget.id,
                                    widget.deleteCounter, widget.title);
                                showOptions = false;
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}

class BlurFilter extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final double radius;
  const BlurFilter({
    super.key,
    required this.child,
    this.sigmaX = 1.5,
    this.sigmaY = 1.5,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sigmaX,
              sigmaY: sigmaY,
            ),
            child: Opacity(
              opacity: 0.01,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
