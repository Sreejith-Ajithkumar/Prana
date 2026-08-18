import 'package:permission_handler/permission_handler.dart';

abstract interface class ActivityRecognitionPermission {
  Future<bool> isGranted();

  Future<bool> request();
}

class PermissionHandlerActivityRecognitionPermission
    implements ActivityRecognitionPermission {
  const PermissionHandlerActivityRecognitionPermission();

  @override
  Future<bool> isGranted() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  @override
  Future<bool> request() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }
}
