# Windows and Android Setup

## Project location

```text
D:\Development\Projects\Prana
```

## Flutter app location

```text
D:\Development\Projects\Prana\apps\mobile
```

## Common commands

```powershell
cd D:\Development\Projects\Prana\apps\mobile
flutter doctor -v
flutter pub get
flutter run
```

## Accept Android licenses

```powershell
flutter doctor --android-licenses
```

## Clean build

```powershell
flutter clean
flutter pub get
flutter run
```

## Notes

- Android development is supported on Windows.
- iOS builds require macOS, Xcode, and CocoaPods.
- Visual Studio warnings can be ignored while only targeting Android.
