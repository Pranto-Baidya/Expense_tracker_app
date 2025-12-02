

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService{

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initNotification()async{

    tz.initializeTimeZones();
    final String currentTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimezone));

    AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    InitializationSettings initializationSettings = InitializationSettings(
     android: androidInitializationSettings
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void>requestPermission()async{
   flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
        'money_manager',
        'MoneyMate',
         importance: Importance.max,
         priority: Priority.high,
         playSound: true
    )
  );

  static Future<void> showImmediateNotification() async {
    await flutterLocalNotificationsPlugin.show(
      0,
      'MoneyMate',
      "You'll now receive notifications",
      notificationDetails,
    );
  }

  static Future<void> sendNotificationAt()async{
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year,now.month,now.day,21,59);

    if(scheduledDate.isBefore(tz.TZDateTime.now(tz.local))){
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'MoneyMate',
        "Don't forget to add your record today",
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time
    );
  }

  static void cancelNotification()async{
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}