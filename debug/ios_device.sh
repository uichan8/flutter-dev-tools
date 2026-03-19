#!/bin/bash
# iOS 실기기 디버그 빌드 및 실행 스크립트
# 사용법: USB로 기기 연결 후 ./scripts/debug/ios_device.sh

set -e

# 헬퍼 로드 및 설정 확인
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_helpers.sh"
ensure_config

if [ ! -f "$ENV_FILE" ]; then
    echo "오류: $ENV_FILE 파일이 없습니다."
    exit 1
fi

echo "=== iOS 실기기 디버그 빌드 ==="

# USB 연결된 iOS 기기 확인
DEVICE_ID=$(flutter devices | grep -i "ios\|iphone\|ipad" | grep -iv "simulator" | head -1 | awk -F'•' '{print $2}' | xargs)

if [ -z "$DEVICE_ID" ]; then
    echo "오류: USB로 연결된 iOS 기기를 찾을 수 없습니다."
    echo ""
    echo "확인 사항:"
    echo "  1. USB 케이블로 기기가 연결되어 있는지 확인"
    echo "  2. 기기에서 '이 컴퓨터를 신뢰하겠습니까?' 팝업을 승인했는지 확인"
    echo "  3. 기기가 잠금 해제 상태인지 확인"
    echo "  4. Xcode에서 개발자 프로비저닝이 설정되어 있는지 확인"
    echo ""
    echo "flutter devices 출력:"
    flutter devices
    exit 1
fi

echo "디바이스: $DEVICE_ID"
echo "디버그 빌드 시작..."
flutter run -d "$DEVICE_ID" --dart-define-from-file=$ENV_FILE
