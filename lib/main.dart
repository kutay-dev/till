import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'dart:io' show File;
import 'package:get_storage/get_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await GetStorage.init();
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const App());
}

final box = GetStorage();

RateMyApp rateMyApp = RateMyApp(
  preferencesPrefix: 'rateMyApp_',
  minLaunches: 2,
  remindLaunches: 3,
  googlePlayIdentifier: 'com.vdev.till',
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        splashColor: Colors.white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.white30,
          selectionHandleColor: Colors.white30,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

List counterObj = box.read("counterObj") ?? [];

dynamic size;
dynamic textScale;

late DateTime date;
late String dateStr;
final TextEditingController titleController = TextEditingController();

final ScrollController counterListScrollController = ScrollController();

bool set24HourFormat = box.read("set24HourFormat") ?? true;
bool setHaptic = box.read("setHaptic") ?? true;

double confirmDeleteButtonsOpacity = 0;

List<Color> primaryGradient = gradients[box.read("primaryGradient") ?? 0];

List<List<Color>> gradients = [
  [
    const Color.fromARGB(255, 84, 113, 182),
    const Color.fromARGB(255, 114, 174, 224),
  ],
  [
    const Color.fromARGB(255, 142, 98, 203),
    const Color.fromARGB(255, 185, 130, 209),
  ],
  [
    const Color.fromARGB(255, 204, 165, 102),
    const Color.fromARGB(255, 240, 209, 143),
  ],
  [
    const Color.fromARGB(255, 96, 173, 99),
    const Color.fromARGB(255, 143, 213, 145),
  ],
  [
    Colors.black,
    const Color.fromARGB(255, 35, 35, 35),
  ],
];

Color floatingColor = Colors.black;

void hapticFeedback([String impact = "medium"]) {
  if (setHaptic) {
    if (impact == "medium") {
      HapticFeedback.mediumImpact();
    }
    if (impact == "light") {
      HapticFeedback.lightImpact();
    }
  }
}

void scrollToBottom() {
  counterListScrollController.animateTo(
    counterListScrollController.position.maxScrollExtent,
    duration: const Duration(milliseconds: 500),
    curve: Curves.ease,
  );
}

void scrollToBottomAsync() async {
  await Future.delayed(const Duration(milliseconds: 500));
  scrollToBottom();
}

class _MainState extends State<Main> {
  List counterCards = [];

  PickedFile? selected;
  CroppedFile? croppedSelected;

  ValueNotifier<String> croppedSelectedPath = ValueNotifier("");

  bool reverseCounters = false;

  Future<void> pickImage() async {
    selected = await ImagePicker().getImage(source: ImageSource.gallery);
  }

  void cropImage() async {
    croppedSelected = await ImageCropper().cropImage(
      sourcePath: selected!.path,
      aspectRatio: const CropAspectRatio(ratioX: 10, ratioY: 3.5),
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    croppedSelectedPath.value = croppedSelected!.path;
    setState(() {});
  }

  @override
  void initState() {
    getCounterCards();
    scrollToBottomAsync();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await rateMyApp.init();
      if (mounted && rateMyApp.shouldOpenDialog) {
        rateMyApp.showRateDialog(context);
      }
    });
  }

  void getCounterCards() {
    counterCards.clear();
    for (int i = 0; i < counterObj.length; i++) {
      counterCards.add(CounterCard(
        title: counterObj[i]["title"],
        id: counterObj[i]["id"],
        firstLeft: counterObj[i]["left"],
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

  void addCounterCard() async {
    int id = Random().nextInt(1000000);
    DateTime now = DateTime.now();
    double left = date.difference(now).inSeconds.toDouble();

    counterObj.add({
      "title": titleController.text,
      "id": id,
      "left": left,
      "date": dateStr,
      "done": false,
      "image": croppedSelected != null ? croppedSelected!.path : "null",
    });

    box.write("counterObj", counterObj);
    getCounterCards();
    selected = null;
    croppedSelected = null;
    titleController.clear();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
    animateFloatingButtons();
    scrollToBottom();
  }

  void sortCounters() {
    counterObj.sort((a, b) => a["left"].compareTo(b["left"]));
    reverseCounters = !reverseCounters;
    if (reverseCounters) {
      counterObj = counterObj.reversed.toList();
    }

    getCounterCards();
  }

  void showAddCounterSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(window.viewPadding.top > 100 ? 40 : 0),
        ),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          child: Stack(
            children: [
              Positioned(
                top: size.height / 7,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                          fontSize: 18.0 * (size.height * 0.0011),
                          color: Colors.black),
                    ),
                  ),
                  child: SizedBox(
                    height: size.height / 1.3,
                    width: size.width,
                    child: CupertinoDatePicker(
                      use24hFormat: set24HourFormat,
                      initialDateTime: DateTime.now(),
                      onDateTimeChanged: (value) {
                        date = value;
                      },
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(
                    bottom: window.viewPadding.bottom > 100 ? 50 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 57.5,
                      height: 57.5,
                      child: ElevatedButton(
                        onPressed: () {
                          hapticFeedback();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpeacialDaysPage(
                                  addCounterCard: addCounterCard),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.black,
                            foregroundColor: Colors.grey[400]),
                        child: const Icon(
                          Icons.star_border,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 148,
                      height: 57.5,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text != "") {
                            hapticFeedback();
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
                                  fontSize: 18 / textScale);
                              return;
                            }

                            if (diff.isNegative) {
                              Navigator.of(context).pop();
                              addCounterCard();
                              setState(() {});
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          backgroundColor: Colors.black,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          "Add Counter",
                          style: TextStyle(
                            fontSize: 14 / textScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 57.5,
                      height: 57.5,
                      child: ElevatedButton(
                        onPressed: () {
                          hapticFeedback();
                          pickImage().then((value) {
                            cropImage();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.black,
                          foregroundColor: Colors.grey[400],
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: window.viewPadding.top > 100 ? 40 : 15,
                child: SizedBox(
                  width: size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: primaryGradient,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGradient[0].withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 10,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      width: size.width,
                      height: 110,
                      child: Stack(
                        children: [
                          BlurFilter(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ValueListenableBuilder(
                                valueListenable: croppedSelectedPath,
                                builder: (context, value, child) {
                                  return croppedSelected != null
                                      ? SizedBox(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: Image.file(
                                            File(value),
                                            fit: BoxFit.cover,
                                            colorBlendMode: BlendMode.darken,
                                            color: Colors.black12,
                                          ),
                                        )
                                      : const SizedBox();
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 22,
                            left: 25,
                            child: CircularPercentIndicator(
                              radius: 35,
                              lineWidth: 5,
                              percent: 1,
                              progressColor: Colors.white,
                              backgroundColor: Colors.white10,
                              circularStrokeCap: CircularStrokeCap.square,
                              center: Text(
                                "100%",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14 / textScale,
                                ),
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
                                maxLength: 15,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: "TITLE",
                                  hintStyle: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14 / textScale,
                                  ),
                                  counterStyle:
                                      const TextStyle(color: Colors.white60),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white38),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 1, color: Colors.white10),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 18 / textScale,
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
  }

  double floatingAddButtonPosition = 0;
  double floatingSortButtonBottomPosition = 0;
  double floatingSortButtonRightPosition = 0;
  double floatingDeleteButtonPosition = 0;
  double floatingAddButtonOpacity = 0;
  double floatingSortButtonOpacity = 0;
  double floatingDeleteButtonOpacity = 0;

  void impactFloatingButtonsSynchronously() async {
    hapticFeedback("light");
    await Future.delayed(const Duration(milliseconds: 50));
    hapticFeedback("light");
    await Future.delayed(const Duration(milliseconds: 50));
    hapticFeedback("light");
  }

  void animateFloatingButtons() async {
    floatingDeleteIconsOpacity = 0;
    floatingIconsOpacity = 1;
    floatingAddButtonPosition = floatingAddButtonPosition == 0 ? 90 : 0;
    floatingAddButtonOpacity = floatingAddButtonOpacity == 0 ? 1 : 0;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 50));
    floatingSortButtonBottomPosition =
        floatingSortButtonBottomPosition == 0 ? 70 : 0;
    floatingSortButtonRightPosition =
        floatingSortButtonRightPosition == 0 ? 70 : 0;
    floatingSortButtonOpacity = floatingSortButtonOpacity == 0 ? 1 : 0;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 50));
    floatingDeleteButtonPosition = floatingDeleteButtonPosition == 0 ? 90 : 0;
    floatingDeleteButtonOpacity = floatingDeleteButtonOpacity == 0 ? 1 : 0;

    setState(() {});
  }

  double floatingIconsOpacity = 1;
  double floatingDeleteIconsOpacity = 0;

  void animateDeleteButtons() async {
    if (floatingDeleteIconsOpacity == 0) {
      floatingIconsOpacity = floatingIconsOpacity == 1 ? 0 : 1;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 100));
      floatingDeleteIconsOpacity = floatingDeleteIconsOpacity == 0 ? 1 : 0;
      setState(() {});
    } else {
      setState(() {});
      floatingDeleteIconsOpacity = floatingDeleteIconsOpacity == 0 ? 1 : 0;
      await Future.delayed(const Duration(milliseconds: 100));
      floatingIconsOpacity = floatingIconsOpacity == 1 ? 0 : 1;
      setState(() {});
    }
  }

  void deleteAllCounters() {
    counterObj.clear();
    getCounterCards();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    size = MediaQuery.of(context).size;
    textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 100,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Use 24 hour format",
                        style: TextStyle(fontSize: 14 / textScale),
                      ),
                      Switch(
                        activeTrackColor: primaryGradient[1],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: primaryGradient[0],
                        activeColor: Colors.white,
                        value: set24HourFormat,
                        onChanged: (value) {
                          hapticFeedback();
                          set24HourFormat = value;
                          setState(() {});
                          box.write("set24HourFormat", set24HourFormat);
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Use haptic feedback",
                        style: TextStyle(fontSize: 14 / textScale),
                      ),
                      Switch(
                        activeTrackColor: primaryGradient[1],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: primaryGradient[0],
                        activeColor: Colors.white,
                        value: setHaptic,
                        onChanged: (value) {
                          hapticFeedback();
                          setHaptic = value;
                          setState(() {});
                          box.write("setHaptic", setHaptic);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () {
                      hapticFeedback();
                      confirmDeleteButtonsOpacity =
                          confirmDeleteButtonsOpacity == 0 ? 1 : 0;
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Delete all counters",
                      style: TextStyle(fontSize: 14 / textScale),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: confirmDeleteButtonsOpacity,
                    child: SizedBox(
                      width: 300,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (confirmDeleteButtonsOpacity == 1) {
                                hapticFeedback();
                                confirmDeleteButtonsOpacity = 0;
                                setState(() {});
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              surfaceTintColor: Colors.transparent,
                              backgroundColor: Colors.black12,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "No",
                              style: TextStyle(fontSize: 14 / textScale),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (confirmDeleteButtonsOpacity == 1) {
                                hapticFeedback();
                                deleteAllCounters();
                                Navigator.pop(context);
                                impactFloatingButtonsSynchronously();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              surfaceTintColor: Colors.transparent,
                              backgroundColor: Colors.black12,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Yes",
                              style: TextStyle(
                                  fontSize: 14 / textScale,
                                  color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: size.height / 20,
                  ),
                  Text(
                    "Theme",
                    style: TextStyle(
                      fontSize: 22 / textScale,
                      color: Colors.black87,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      color: const Color.fromARGB(45, 0, 0, 0),
                      height: 1,
                      width: size.width / 1.8,
                    ),
                  ),
                  SizedBox(
                    width: size.width / 2,
                    child: InkWell(
                      splashColor: gradients[0][1].withOpacity(0.2),
                      highlightColor: Colors.transparent,
                      onTap: () {
                        hapticFeedback();
                        primaryGradient = gradients[0];
                        setState(() {});
                        box.write("primaryGradient", 0);
                      },
                      child: GradientText(
                        "SAPPHIRE",
                        gradient: LinearGradient(
                          colors: [
                            gradients[0][0],
                            gradients[0][0],
                            gradients[0][1],
                            gradients[0][1],
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 15 / textScale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height / 80),
                  SizedBox(
                    width: size.width / 2,
                    child: InkWell(
                      splashColor: gradients[1][1].withOpacity(0.2),
                      highlightColor: Colors.transparent,
                      onTap: () {
                        hapticFeedback();
                        primaryGradient = gradients[1];
                        setState(() {});
                        box.write("primaryGradient", 1);
                      },
                      child: GradientText(
                        "AMETHYST",
                        gradient: LinearGradient(
                          colors: [
                            gradients[1][0],
                            gradients[1][0],
                            gradients[1][1],
                            gradients[1][1],
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 15 / textScale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height / 80),
                  SizedBox(
                    width: size.width / 2,
                    child: InkWell(
                      splashColor: gradients[2][1].withOpacity(0.2),
                      highlightColor: Colors.transparent,
                      onTap: () {
                        hapticFeedback();
                        primaryGradient = gradients[2];
                        setState(() {});
                        box.write("primaryGradient", 2);
                      },
                      child: GradientText(
                        "GOLD",
                        gradient: LinearGradient(
                          colors: [
                            gradients[2][0],
                            gradients[2][0],
                            gradients[2][1],
                            gradients[2][1],
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 15 / textScale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height / 80),
                  SizedBox(
                    width: size.width / 2,
                    child: InkWell(
                      splashColor: gradients[3][1].withOpacity(0.2),
                      highlightColor: Colors.transparent,
                      onTap: () {
                        hapticFeedback();
                        primaryGradient = gradients[3];
                        setState(() {});
                        box.write("primaryGradient", 3);
                      },
                      child: GradientText(
                        "EMERALD",
                        gradient: LinearGradient(
                          colors: [
                            gradients[3][0],
                            gradients[3][0],
                            gradients[3][1],
                            gradients[3][1],
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 15 / textScale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height / 80),
                  SizedBox(
                    width: size.width / 2,
                    child: InkWell(
                      splashColor: gradients[4][1].withOpacity(0.2),
                      highlightColor: Colors.transparent,
                      onTap: () {
                        hapticFeedback();
                        primaryGradient = gradients[4];
                        setState(() {});
                        box.write("primaryGradient", 4);
                      },
                      child: GradientText(
                        "OBSIDIAN",
                        gradient: const LinearGradient(
                          colors: [
                            Colors.black,
                            Colors.black45,
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 15 / textScale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              child: Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      if (!await launchUrl(Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.vdev.till'))) {
                        throw Exception('Could not launch the page');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black45,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: Text(
                      "Rate Us",
                      style: TextStyle(fontSize: 14 / textScale),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (!await launchUrl(
                          Uri.parse('https://vanta-tech.vercel.app/privacy'))) {
                        throw Exception('Could not launch the page');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black45,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: Text(
                      "Privacy Policy",
                      style: TextStyle(fontSize: 14 / textScale),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: BlurFilter(
              radius: 100,
              sigmaX: 10,
              sigmaY: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryGradient[0].withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
                width: 60,
                height: 60,
              ),
            ),
          ),
          AnimatedPositioned(
            bottom: 0,
            right: floatingAddButtonPosition,
            duration: const Duration(milliseconds: 150),
            curve: Curves.ease,
            child: AnimatedOpacity(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 150),
              opacity: floatingAddButtonOpacity,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: const BorderRadius.all(
                    Radius.circular(100),
                  ),
                ),
                child: IconButton(
                  color: Colors.white,
                  icon: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: floatingIconsOpacity,
                        duration: const Duration(milliseconds: 100),
                        child: const Icon(Icons.add),
                      ),
                      AnimatedOpacity(
                        opacity: floatingDeleteIconsOpacity,
                        duration: const Duration(milliseconds: 100),
                        child: const Icon(Icons.check),
                      ),
                    ],
                  ),
                  onPressed: () {
                    if (floatingDeleteIconsOpacity == 0) {
                      hapticFeedback();
                      showAddCounterSheet();
                    } else {
                      deleteAllCounters();
                      animateFloatingButtons();
                      impactFloatingButtonsSynchronously();
                    }
                  },
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            bottom: floatingSortButtonBottomPosition,
            right: floatingSortButtonRightPosition,
            duration: const Duration(milliseconds: 150),
            curve: Curves.ease,
            child: AnimatedOpacity(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 150),
              opacity: floatingSortButtonOpacity,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      counterCards.length > 1
                          ? primaryGradient[0]
                          : primaryGradient[0].withOpacity(0.3),
                      counterCards.length > 1
                          ? primaryGradient[1]
                          : primaryGradient[1].withOpacity(0.3),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                  //color: counterObj.length > 1 ? floatingColor : Colors.black54,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(100),
                  ),
                ),
                child: IconButton(
                  color: Colors.white,
                  icon: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: floatingIconsOpacity,
                        duration: const Duration(milliseconds: 100),
                        child: const Icon(Icons.sort),
                      ),
                      AnimatedOpacity(
                        opacity: floatingDeleteIconsOpacity,
                        duration: const Duration(milliseconds: 100),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  onPressed: () {
                    if (counterObj.length > 1) {
                      hapticFeedback();
                    }
                    if (floatingDeleteIconsOpacity == 0) {
                      sortCounters();
                    } else {
                      animateDeleteButtons();
                    }
                  },
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            bottom: floatingDeleteButtonPosition,
            right: 0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.ease,
            child: AnimatedOpacity(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 150),
              opacity: floatingDeleteButtonOpacity,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: primaryGradient,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: const BorderRadius.all(
                    Radius.circular(100),
                  ),
                ),
                child: Builder(builder: (context) {
                  return IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      hapticFeedback();
                      Scaffold.of(context).openDrawer();
                    },
                  );
                }),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: SizedBox(
              width: 60,
              height: 60,
              child: IconButton(
                color: Colors.white,
                splashRadius: 30,
                onPressed: () {
                  animateFloatingButtons();
                  impactFloatingButtonsSynchronously();
                },
                icon: const Icon(
                  Icons.more_horiz,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          (counterCards.isNotEmpty
              ? ReorderableListView(
                  buildDefaultDragHandles: false,
                  scrollController: counterListScrollController,
                  padding: const EdgeInsets.only(top: 50, bottom: 200),
                  onReorder: (oldIndex, newIndex) {
                    hapticFeedback();
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
  late double optionsButtonsBottom;
  late double optionTextFieldBottom;

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
    cardHeight = 110;
    optionsButtonsBottom = 0;
    optionTextFieldBottom = -15;
    super.initState();
  }

  Future<void> pickImage() async {
    selected = await ImagePicker().getImage(source: ImageSource.gallery);
  }

  CroppedFile? croppedSelected;

  void cropImage() async {
    croppedSelected = await ImageCropper().cropImage(
      sourcePath: selected!.path,
      aspectRatio: const CropAspectRatio(ratioX: 10, ratioY: 3.5),
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );

    widget.image = croppedSelected!.path;

    setState(() {});
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
    cardHeight = cardHeight == 110 ? 170 : 110;
    setState(() {});
  }

  void animateConfirmDeleteHeight() async {
    cardHeight = cardHeight == 170 ? 220 : 170;
    await Future.delayed(const Duration(milliseconds: 150));
    optionsButtonsBottom = optionsButtonsBottom == 0 ? 50 : 0;
    optionTextFieldBottom = optionTextFieldBottom == -15 ? 35 : -15;
    setState(() {});
  }

  double optionsOpacity = 0;

  void animateOptionsOpacity() {
    optionsOpacity = optionsOpacity == 1 ? 0 : 1;
    setState(() {});
  }

  double confirmDeleteOpacity = 0;

  void animateConfirmDeleteOpacity(double opacity) {
    confirmDeleteOpacity = opacity;
    setState(() {});
  }

  bool deleteEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: AnimatedContainer(
        curve: Curves.ease,
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.image == "null"
                  ? primaryGradient[0].withOpacity(0.4)
                  : Colors.black38,
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: primaryGradient,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(22),
            ),
          ),
          child: Stack(
            children: [
              widget.image == "null"
                  ? const SizedBox()
                  : BlurFilter(
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
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
                top: 22,
                left: 25,
                child: CircularPercentIndicator(
                  radius: 35,
                  lineWidth: 5,
                  percent: (100 + perc) / 100,
                  progressColor: Colors.white,
                  backgroundColor: Colors.white10,
                  circularStrokeCap: CircularStrokeCap.square,
                  center: (widget.done
                      ? Icon(
                          Icons.check,
                          size: 27 / textScale,
                          color: Colors.white,
                        )
                      : Text(
                          (100 + perc).toStringAsFixed(0) == "100"
                              ? "99%"
                              : "${(100 + perc).toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 / textScale,
                          ),
                        )),
                ),
              ),
              Positioned(
                top: 20,
                left: 110,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: size.width * 0.4,
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.title.toString().toUpperCase(),
                              style: TextStyle(
                                fontSize:
                                    (18.0 * textScale) * (size.width * 0.0027),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: (13.5 * textScale) *
                                                  (size.width * 0.0023)),
                                        ),
                                        Text(
                                          "H: $hoursLeft",
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: (13.5 * textScale) *
                                                  (size.width * 0.0023)),
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
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: (13.5 * textScale) *
                                                  (size.width * 0.0023)),
                                        ),
                                        Text(
                                          "S: ${left.toStringAsFixed(0)}",
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: (13.5 * textScale) *
                                                  (size.width * 0.0023)),
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
                    if (titleController.text != "") {
                      hapticFeedback();
                      animateCardHeight();
                      animateOptionsOpacity();
                      if (showOptions) {
                        counterObj[rank]["title"] = titleController.text;
                        selected != null
                            ? counterObj[rank]["image"] = croppedSelected!.path
                            : null;
                        box.write("counterObj", counterObj);
                        await Future.delayed(const Duration(milliseconds: 150));
                        widget.getCounterCards();
                      }
                      showOptions = !showOptions;
                      animateConfirmDeleteOpacity(0);
                      if (showOptions) {
                        deleteEnabled = true;
                      }

                      setState(() {});
                    }
                  },
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: confirmDeleteOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        width: 70,
                        height: 35,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            backgroundColor: Colors.black26,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          onPressed: (() {
                            hapticFeedback();
                            animateConfirmDeleteHeight();
                            animateConfirmDeleteOpacity(0);
                            deleteEnabled = true;
                            setState(() {});
                          }),
                          child: Text(
                            "no",
                            style: TextStyle(fontSize: 14 / textScale),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        width: 70,
                        height: 35,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          onPressed: (() {
                            hapticFeedback();
                            widget.deleteCounter(rank);
                          }),
                          child: Text(
                            "yes",
                            style: TextStyle(fontSize: 14 / textScale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: optionsOpacity,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      bottom: optionsButtonsBottom,
                      right: 0,
                      child: IconButton(
                        color: Colors.white,
                        onPressed: () async {
                          if (optionsOpacity == 1) {
                            hapticFeedback();
                            pickImage().then((value) {
                              cropImage();
                              setState(() {});
                            });
                          }
                        },
                        icon: const Icon(Icons.image_outlined),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      bottom: optionTextFieldBottom,
                      left: 85,
                      right: 85,
                      child: TextField(
                        enabled: showOptions,
                        maxLength: 15,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: widget.title == "" ? "TITLE" : "",
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 14 / textScale,
                          ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14 / textScale,
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      bottom: optionsButtonsBottom,
                      left: 0,
                      child: IconButton(
                        color: Colors.white,
                        onPressed: () {
                          if (optionsOpacity == 1 && deleteEnabled) {
                            hapticFeedback();
                            animateConfirmDeleteHeight();
                            animateConfirmDeleteOpacity(1);
                            if (confirmDeleteOpacity == 1) {
                              deleteEnabled = false;
                            }
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 45,
                height: 35,
                child: ReorderableDragStartListener(
                  index: rank,
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.white24,
                  ),
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

class SpeacialDaysPage extends StatefulWidget {
  const SpeacialDaysPage({required this.addCounterCard, super.key});
  final dynamic addCounterCard;

  @override
  State<SpeacialDaysPage> createState() => _SpeacialDaysPageState();
}

class _SpeacialDaysPageState extends State<SpeacialDaysPage> {
  final List days = [
    {
      "title": "New Year",
      "date": "January 1",
      "datetime": "2024-01-01 00:00:00.00",
    },
    {
      "title": "Christmas Eve",
      "date": "December 24",
      "datetime": "2023-12-24 18:00:00.00",
    },
    {
      "title": "Thanksgiving",
      "date": "November 23",
      "datetime": "2023-11-23 00:00:00.00",
    },
    {
      "title": "Halloween",
      "date": "October 31",
      "datetime": "2023-10-31 00:00:00.00",
    },
    {
      "title": "Mother's Day",
      "date": "May 14",
      "datetime": "2023-05-14 00:00:00.00",
    },
    {
      "title": "Father's Day",
      "date": "June 18",
      "datetime": "2023-06-18 00:00:00.00",
    },
    {
      "title": "Valentine's day",
      "date": "February 14",
      "datetime": "2023-02-14 00:00:00.00",
    },
    {
      "title": "Easter",
      "date": "April 9",
      "datetime": "2023-04-09 00:00:00.00",
    },
    {
      "title": "Saint Patrick's",
      "date": "March 17",
      "datetime": "2023-03-17 00:00:00.00",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.symmetric(
              vertical: window.viewPadding.top > 100 ? 85 : 70,
            ),
            children: [
              for (int i = 0; i < days.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        title: Text(
                          days[i]["title"],
                          style: TextStyle(fontSize: 14 / textScale),
                        ),
                        subtitle: Text(
                          days[i]["date"],
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 14 / textScale,
                          ),
                        ),
                        trailing: SizedBox(
                          height: 50,
                          width: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              hapticFeedback();
                              Navigator.pop(context);
                              date = DateTime.parse(days[i]["datetime"]);
                              dateStr = "$date";
                              titleController.text = days[i]["title"];
                              widget.addCounterCard();
                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.all(0), // to center child
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),

                              shadowColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              foregroundColor: Colors.transparent,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      i != days.length - 1
                          ? const Divider(
                              color: Colors.black12,
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
            ],
          ),
          Container(
            height: window.viewPadding.top > 100 ? 85 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: primaryGradient,
              ),
            ),
          ),
          Positioned(
            top: window.viewPadding.top > 100 ? 35 : 20,
            left: 15,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
