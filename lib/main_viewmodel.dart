import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:goetest/util/location_callback_handler.dart';
import 'dart:async';

import 'package:goetest/util/location_service_repository.dart';
import 'package:location_permissions/location_permissions.dart';

class MainViewModel extends ChangeNotifier{
  bool isRunning;
  String latitude;
  String longtitude;
  ReceivePort port = ReceivePort();
  LocationDto lastLocation;
  String lastRunTxt = "-";

  Future<void> startInit() async{
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
        await updateLocation(data);
        latitude = data.toString();
      },
    );
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    print('Initializing...');
    await BackgroundLocator.initialize();
    print('Initialization done');
    final _isRunning = await BackgroundLocator.isRegisterLocationUpdate();
    isRunning = _isRunning;
    print('Running ${isRunning.toString()}');
  }

   void updateLocation(LocationDto locationDto) {

        if (locationDto != null) {
          lastLocation = locationDto;
          latitude = locationDto.latitude.toString();
        //  lastTimeLocation = DateTime.now();


        }
        notifyListeners();
    }

  void onStart() async {
    if (await _checkLocationPermission()) {
      LocationPermissions().serviceStatus.listen((event) {
        if(event == ServiceStatus.disabled){
          print('Location Disabled');
         // testAlert(context);
        }else{
          print('Location Enabled');
          _startLocator();

            isRunning = true;
         //   lastTimeLocation = null;

          if (isRunning != null) {
            if (isRunning) {
              if ( lastLocation == null) {
                latitude = "???";
              } else {
                latitude =
                    LocationServiceRepository.formatLog(lastLocation);
              }
            }
          }


        }
      });

    } else {
      // show error
    }

    notifyListeners();
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


}