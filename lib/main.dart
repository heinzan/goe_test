import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_intent/android_intent.dart';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:flutter/material.dart';
import 'package:goetest/locationVO.dart';
import 'package:goetest/main_viewmodel.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:provider/provider.dart';
import 'util/file_manager.dart';
import 'util/location_callback_handler.dart';
import 'util/location_service_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp( MaterialApp(home: MyApp()),
  );

}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{

  MainViewModel _mainViewModel = MainViewModel();
  ReceivePort port = ReceivePort();

  String logStr = '';
  bool isRunning;
  LocationDto lastLocation;
  DateTime lastTimeLocation;


  @override
  void initState() {
    // TODO: implement initState
    _mainViewModel.startInit();
    super.initState();
  }
  /*@override
  void initState() {
    super.initState();

    if (IsolateNameServer.lookupPortByName(
        LocationServiceRepository.isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          LocationServiceRepository.isolateName);
    }

    IsolateNameServer.registerPortWithName(
        port.sendPort, LocationServiceRepository.isolateName);

    port.listen(
          (dynamic data) async {
        await updateUI(data);
      },
    );
    initPlatformState();
  }

*//*  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If user resumed to this app, check permission
    if(state == AppLifecycleState.resumed) {
      LocationPermissions().serviceStatus.listen((event) {
        if(event == ServiceStatus.disabled){
          print('Location Disabled');
          testAlert(context); // Show dialog
        }else{
        //  testAlert(context); //I want hide dialog when user enable location.How do?
          print('Location Enabled');
        }
      });
          }
      }*//*

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> updateUI(LocationDto data) async {
    final log = await FileManager.readLogFile();
    setState(() {
      if (data != null) {
        lastLocation = data;
        lastTimeLocation = DateTime.now();
      }
      logStr = log;
    });
  }

  Future<void> initPlatformState() async {
    print('Initializing...');
    await BackgroundLocator.initialize();
    logStr = await FileManager.readLogFile();
    print('Initialization done');
    final _isRunning = await BackgroundLocator.isRegisterLocationUpdate();
    setState(() {
      isRunning = _isRunning;
    });
    print('Running ${isRunning.toString()}');
  }
*/
  @override
  Widget build(BuildContext context) {
    final stop = SizedBox(
      width: double.maxFinite,
      child: RaisedButton(
        child: Text('Stop'),
        onPressed: () {
          onStop();
        },
      ),
    );
    final clear = SizedBox(
      width: double.maxFinite,
      child: RaisedButton(
        child: Text('Clear Log'),
        onPressed: () {
          FileManager.clearLogFile();
          setState(() {
            logStr = '';
          });
        },
      ),
    );
    String msgStatus = "-";
    if (isRunning != null) {
      if (isRunning) {
        msgStatus = 'Is running';
      } else {
        msgStatus = 'Is not running';
      }
    }
    final status = Text("Status: $msgStatus");


    final log = Text(
      logStr,
    );
      return ChangeNotifierProvider<MainViewModel>(
          create: (context) =>MainViewModel(),
          child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Flutter background Locator'),
            ),
            body: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                SizedBox(
                width: double.maxFinite,
                  child: Consumer<MainViewModel>(
                    builder: (context , mm , child){
                      return RaisedButton(
                        child: Text('Start'),
                        onPressed: () {
                          mm.onStart();
                        },
                      );
                    },

                  ),
                ),

                    stop, clear, status,
                   Consumer<MainViewModel>(builder: (context , repo , child){
                     return     Text(
                         repo.latitude == null ?"asdf": repo.latitude
                     );
                   }),





                    log],
                ),
              ),
            ),
          ),
        ),
      );

  }

  void onStop() {
    BackgroundLocator.unRegisterLocationUpdate();
    setState(() {
      isRunning = false;
      lastTimeLocation = null;
      lastLocation = null;
    });
  }

  void _onStart() async {
    if (await _checkLocationPermission()) {
      LocationPermissions().serviceStatus.listen((event) {
        if(event == ServiceStatus.disabled){
          print('Location Disabled');
          testAlert(context);
        }else{
          print('Location Enabled');
          _startLocator();
          setState(() {
            isRunning = true;
            lastTimeLocation = null;
            lastLocation = null;
          });
        }
      });

    } else {
      // show error
    }
  }

  void openLocationSetting() async {
    final AndroidIntent intent = new AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }
  Future<bool> _checkLocationPermission() async {
    final access = await LocationPermissions().checkPermissionStatus();
    switch (access) {
      case PermissionStatus.unknown:
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await LocationPermissions().requestPermissions(
          permissionLevel: LocationPermissionLevel.locationAlways,
        );
        if (permission == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
        break;
      case PermissionStatus.granted:
        return true;
        break;
      default:
        return false;
        break;
    }
  }


  void _startLocator() {
    Map<String, dynamic> data = {'countInit': 1};
    BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
/*
        Comment initDataCallback, so service not set init variable,
        variable stay with value of last run after unRegisterLocationUpdate
 */
      disposeCallback: LocationCallbackHandler.disposeCallback,
      androidNotificationCallback: LocationCallbackHandler.notificationCallback,
      settings: LocationSettings(
          notificationChannelName: "Location tracking service",
          notificationTitle: "Start Location Tracking example",
          notificationMsg: "Track location in background example",
          wakeLockTime: 20,
          autoStop: false,
          interval: 5),
    );
  }

    void testAlert(BuildContext context){

      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Location service disable"),
            content: new Text("You must enable your location access"),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("Go Setting"),
                onPressed: () {
                  openLocationSetting();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }

}

