#!/bin/bash
# iOS 아카이브 준비 스크립트
#
# Xcode에서 Product > Archive 실행 전에 한 번 돌려야 .env 값이
# Generated.xcconfig 의 DART_DEFINES 에 최신으로 주입된다.
#
# 사용법:
#   ./script/ios_archive_prep.sh

set -e

# CocoaPods UTF-8 요구사항 (Ruby 4.x + cocoapods 1.16 조합 호환성)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# .env 확인
if [ ! -f "$ENV_FILE" ]; then
    echo "오류: $ENV_FILE 파일이 없습니다."
    exit 1
fi

echo "====================================="
echo "  iOS 아카이브 준비 (.env 주입)"
echo "====================================="
echo ""

echo "[1/3] Flutter 패키지 동기화..."
flutter pub get

echo ""
echo "[2/3] .env → Generated.xcconfig 의 DART_DEFINES 주입..."
flutter build ios --config-only --dart-define-from-file="$ENV_FILE"

echo ""
echo "[3/3] CocoaPods 설치..."
cd ios
pod install
cd ..

echo ""
echo "====================================="
echo "  준비 완료"
echo "====================================="
echo ""
echo "다음 단계:"
echo "  1. Xcode에서 ios/Runner.xcworkspace 열기"
echo "     open ios/Runner.xcworkspace"
echo "  2. 상단 디바이스 선택에서 'Any iOS Device (arm64)' 선택"
echo "  3. Product > Archive 실행"
echo "  4. Organizer 에서 Distribute App 진행"
echo ""
echo "주의:"
echo "  - .env 값을 변경했거나, 다른 브랜치 체크아웃 후에는"
echo "    이 스크립트를 다시 실행해야 DART_DEFINES 가 최신 상태가 됩니다."
