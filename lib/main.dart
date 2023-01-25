import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  ValueNotifier<String> selectedPath = ValueNotifier("");

  Future<void> pickImage() async {
    selected = await ImagePicker().getImage(source: ImageSource.gallery);
    selectedPath.value = selected!.path;
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
                  isScrollControlled: true,
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (BuildContext context) {
                    return SizedBox(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 115,
                            child: CupertinoTheme(
                              data: const CupertinoThemeData(
                                textTheme: CupertinoTextThemeData(
                                  dateTimePickerTextStyle: TextStyle(
                                      fontSize: 18, color: Colors.black),
                                ),
                              ),
                              child: SizedBox(
                                height: size.height / 1.2,
                                width: size.width,
                                child: CupertinoDatePicker(
                                  initialDateTime: DateTime.now(),
                                  onDateTimeChanged: (value) {
                                    date = value;
                                  },
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(bottom: 50),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 170,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  late Duration diff;
                                  try {
                                    DateTime now = DateTime.now();
                                    dateStr = "$date";
                                    diff = now.difference(date);
                                  } catch (e) {
                                    Fluttertoast.showToast(
                                        msg: "Enter a valid time",
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.CENTER,
                                        timeInSecForIosWeb: 2,
                                        backgroundColor: Colors.red[300],
                                        textColor: Colors.white,
                                        fontSize: 18);
                                    return;
                                  }

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
                          Positioned(
                            bottom: 50,
                            right: size.width / 10,
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.black87,
                                ),
                                onPressed: () {
                                  pickImage();
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            child: SizedBox(
                              width: size.width,
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 5,
                                        blurRadius: 10,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  width: size.width,
                                  height: 120,
                                  child: Stack(
                                    children: [
                                      BlurFilter(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: ValueListenableBuilder(
                                            valueListenable: selectedPath,
                                            builder: (context, value, child) {
                                              return selected != null
                                                  ? SizedBox(
                                                      width: double.infinity,
                                                      child: Image.file(
                                                        File(value),
                                                        fit: BoxFit.cover,
                                                        colorBlendMode:
                                                            BlendMode.darken,
                                                        color: Colors.black12,
                                                      ),
                                                    )
                                                  : const SizedBox();
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 25,
                                        left: 25,
                                        child: CircularPercentIndicator(
                                          radius: 35,
                                          lineWidth: 5,
                                          percent: 1,
                                          progressColor: Colors.white,
                                          backgroundColor: Colors.white10,
                                          circularStrokeCap:
                                              CircularStrokeCap.round,
                                          center: const Text(
                                            "100%",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 15,
                                        left: 110,
                                        child: SizedBox(
                                          width: 190,
                                          child: TextField(
                                            controller: titleController,
                                            autofocus: true,
                                            maxLength: 12,
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            decoration: const InputDecoration(
                                              hintText: "TITLE",
                                              hintStyle: TextStyle(
                                                  color: Colors.white54),
                                              counterStyle: TextStyle(
                                                  color: Colors.white30),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white30),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    width: 1,
                                                    color: Colors.white10),
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
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
      body: Stack(
        children: [
          (counterCards.isNotEmpty
              ? ReorderableListView(
                  padding: const EdgeInsets.only(top: 50, bottom: 100),
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) {
                      newIndex--;
                    }
                    final counterCard = counterObj.removeAt(oldIndex);
                    counterObj.insert(newIndex, counterCard);
                    getCounterCards();
                    box.write("counterObj", counterObj);
                    setState(() {});
                  },
                  children: [
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

  late int rank;
  late double cardHeight;

  @override
  void initState() {
    for (int i = 0; i < counterObj.length; i++) {
      if (counterObj[i]["id"] == widget.id) {
        rank = i;
        break;
      }
    }
    titleController.text = widget.title.toUpperCase();
    getDifference();
    cardHeight = 120;
    super.initState();
  }

  Future<void> pickImage() async {
    selected = await ImagePicker().getImage(source: ImageSource.gallery);
  }

  @override
  void setState(_) {
    if (mounted) {
      super.setState(_);
    }
  }

  void getDifference() async {
    widget.done = counterObj[rank]["done"];

    while (true) {
      DateTime now = DateTime.now();
      DateTime leftInSecs = DateTime.parse(widget.date);
      left = leftInSecs.difference(now).inSeconds.toDouble();
      perc = ((left - widget.firstLeft) / widget.firstLeft) * 100;
      if (left <= 0) {
        perc = 0;
        counterObj[rank]["done"] = true;
        widget.done = true;
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

        left -= 1;
        box.write("counterObj", counterObj);
      }
      setState(() {});
    }
  }

  void animateCardHeight() {
    cardHeight = cardHeight == 120 ? 170 : 120;
    setState(() {});
  }

  double optionsOpacity = 0;

  void animateOptionsOpacity() {
    optionsOpacity = optionsOpacity == 1 ? 0 : 1;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 25),
      child: AnimatedContainer(
        curve: Curves.ease,
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        height: cardHeight,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              widget.image == "null"
                  ? const SizedBox()
                  : BlurFilter(
                      child: SizedBox(
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
              Positioned(
                top: 25,
                left: 25,
                child: CircularPercentIndicator(
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
              ),
              Positioned(
                top: 25,
                left: 110,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title.toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5),
                                        ),
                                        Text(
                                          "H: $hoursLeft",
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5),
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5),
                                        ),
                                        Text(
                                          "S: ${left.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5),
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
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: optionsOpacity,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                    showOptions ? Icons.check : Icons.more_vert,
                    color: Colors.white54,
                  ),
                  onPressed: () async {
                    animateCardHeight();
                    animateOptionsOpacity();
                    if (showOptions) {
                      counterObj[rank]["title"] = titleController.text;
                      selected != null
                          ? counterObj[rank]["image"] = selected!.path
                          : null;
                      box.write("counterObj", counterObj);
                      await Future.delayed(const Duration(milliseconds: 150));
                      widget.getCounterCards();
                    }
                    showOptions = !showOptions;

                    setState(() {});
                  },
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: optionsOpacity,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        color: Colors.white,
                        onPressed: () {
                          if (optionsOpacity == 1) {
                            pickImage().then((value) {
                              setState(() {
                                widget.image = selected!.path;
                              });
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                      ),
                    ),
                    Positioned(
                      bottom: -15,
                      left: 85,
                      right: 85,
                      child: TextField(
                        enabled: showOptions,
                        maxLength: 12,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: widget.title == "" ? "TITLE" : "",
                          hintStyle: const TextStyle(color: Colors.white54),
                          counterStyle:
                              const TextStyle(color: Colors.transparent),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(width: 1, color: Colors.white38),
                          ),
                        ),
                        controller: titleController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: IconButton(
                        color: Colors.white,
                        onPressed: () {
                          if (optionsOpacity == 1) {
                            confirmDelete(context, widget.id,
                                widget.deleteCounter, widget.title);
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                  ],
                ),
              ),
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
    this.sigmaX = 1.3,
    this.sigmaY = 1.3,
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
