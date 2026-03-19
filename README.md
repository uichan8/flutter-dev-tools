# flutter-dev-tools

Flutter 앱 빌드/실행 도구

## 설치

```bash
git submodule add <repo-url> tools
```

## 초기 설정

```bash
./tools/setting.sh
```

## 에뮬레이터/시뮬레이터

```bash
# iOS
./tools/debug/ios_phone_simulator.sh
./tools/debug/ios_pad_simulator.sh

# Android
./tools/debug/android_phone_emulator.sh
./tools/debug/android_pad_emulator.sh
./tools/debug/android_fold_emulator.sh
```

## 실기기

```bash
./tools/debug/ios_device.sh
./tools/debug/android_device.sh
```

## 릴리즈

```bash
./tools/release.sh
```
