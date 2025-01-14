import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/my_home_page.dart';
import 'package:terpiez/shaker.dart';
import 'user_state_model.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

UserState uS = UserState();
var soundSet = uS.soundSet;
String? ret = '/';
int id = 0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotis();
  ret = await initializeService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (BuildContext context) => UserState(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => Shaker(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

FlutterLocalNotificationsPlugin fLocNotiPlugin =
    FlutterLocalNotificationsPlugin();
String? retVal;

Future<void> initNotis() async {
  AndroidInitializationSettings ais =
      const AndroidInitializationSettings('@mipmap/launcher_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: ais,
  );
  await fLocNotiPlugin.initialize(initializationSettings);
  await fLocNotiPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<String> initializeService() async {
  final service = FlutterBackgroundService();
  final NotificationAppLaunchDetails? nDet =
      await fLocNotiPlugin.getNotificationAppLaunchDetails();

  if (nDet != null && nDet.didNotificationLaunchApp == true) {
    return '/finder';
  }

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    "Terpiez Channels V2",
    "Terpiez Noti!",
    description: "Noti for Terpiez",
    importance: Importance.high,
    playSound: soundSet,
    sound: RawResourceAndroidNotificationSound('nearby_terp'),
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      iOS: DarwinInitializationSettings(),
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: "Terpiez Channels V2",
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  return '/';
}

bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  double? distance;
  LatLng? currPos;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool soundSet = prefs.getBool('soundSet') ?? true;

  service.on("update").listen((e) {
    if (e != null) {
      distance = (e['distance'] as num?)?.toDouble();
      currPos = LatLng(
        (e['lat'] as num?)?.toDouble() ?? 0.0,
        (e['lon'] as num?)?.toDouble() ?? 0.0,
      );
    }
  });
  // print(soundSet);
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (distance! <= 20 && currPos != null && distance != null) {
      flutterLocalNotificationsPlugin.show(
        id++,
        "Terpiez Notification!",
        'A terpiez is close by!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            "id",
            'Noti for Terpiez',
            importance: Importance.max,
            priority: Priority.high,
            playSound: soundSet,
            sound: RawResourceAndroidNotificationSound('nearby_terp'),
          ),
        ),
      );
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Terpiez',
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: MyHomePage(title: 'Terpiez', index: ret == '/finder' ? 1 : 0)
        // home: ret == '/' ? const MyHomePage(title: 'Terpiez') : const FinderTab()
        );
  }
}
