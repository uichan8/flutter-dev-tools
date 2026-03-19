#!/bin/bash
# 디바이스 설정 파일 예시
# 이 파일을 config.sh로 복사한 뒤 본인 환경에 맞게 수정하세요.
# cp scripts/device_config.example.sh scripts/config.sh

# iOS 시뮬레이터 이름 (xcrun simctl list devices 에서 확인)
IOS_SIMULATOR_PHONE="iPhone 16 Pro"
IOS_SIMULATOR_PAD="iPad Pro 13-inch (M4)"

# Android 에뮬레이터 AVD 이름 (emulator -list-avds 에서 확인)
ANDROID_AVD_PHONE="Pixel_9"
ANDROID_AVD_PAD="Pixel_Tablet"

# 환경 변수 파일 경로 (프로젝트 루트 기준)
ENV_FILE=".env"
