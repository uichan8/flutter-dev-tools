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
echo ""

# 연결된 iOS 실기기 목록 가져오기
DEVICE_IDS=()
DEVICE_NAMES=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    local_id=$(echo "$line" | awk -F'•' '{print $2}' | xargs)
    local_name=$(echo "$line" | awk -F'•' '{print $1}' | xargs)
    [ -z "$local_id" ] && continue
    DEVICE_IDS+=("$local_id")
    DEVICE_NAMES+=("$local_name ($local_id)")
done <<< "$(flutter devices | grep -i "ios\|iphone\|ipad" | grep -iv "simulator")"

if [ ${#DEVICE_IDS[@]} -eq 0 ]; then
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

# 기기가 1대면 바로 실행, 2대 이상이면 선택
if [ ${#DEVICE_IDS[@]} -eq 1 ]; then
    DEVICE_ID="${DEVICE_IDS[0]}"
    echo "디바이스: ${DEVICE_NAMES[0]}"
else
    select_menu "기기를 선택하세요:" "${DEVICE_NAMES[@]}"
    DEVICE_ID="${DEVICE_IDS[$MENU_RESULT]}"
    echo "디바이스: ${DEVICE_NAMES[$MENU_RESULT]}"
fi

echo "디버그 빌드 시작..."
flutter run -d "$DEVICE_ID" --dart-define-from-file=$ENV_FILE
