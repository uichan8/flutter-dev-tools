#!/bin/bash
# iOS 패드 시뮬레이터 디버그 빌드 및 실행 스크립트
# 사용법: ./scripts/debug/ios_pad_simulator.sh

set -e

# 헬퍼 로드 및 설정 확인
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_helpers.sh"
ensure_config
ensure_ios_simulator "PAD"

if [ ! -f "$ENV_FILE" ]; then
    echo "오류: $ENV_FILE 파일이 없습니다."
    exit 1
fi

echo "=== iOS 패드 시뮬레이터 디버그 빌드 ==="

# 설정된 시뮬레이터의 UDID 조회
echo "설정된 시뮬레이터: $IOS_SIMULATOR_PAD"
SIM_UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
name = '$IOS_SIMULATOR_PAD'
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for d in devices:
            if d['name'] == name:
                print(d['udid']); sys.exit(0)
print('')
" 2>/dev/null)

if [ -z "$SIM_UDID" ]; then
    echo "오류: '$IOS_SIMULATOR_PAD' 시뮬레이터를 찾을 수 없습니다."
    echo "사용 가능한 시뮬레이터:"
    xcrun simctl list devices available | grep iPad
    echo ""
    echo "scripts/setting.sh 를 실행하여 다시 설정해주세요."
    exit 1
fi

# 시뮬레이터 부팅
BOOT_STATE=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIM_UDID':
            print(d['state']); sys.exit(0)
" 2>/dev/null)

if [ "$BOOT_STATE" != "Booted" ]; then
    echo "시뮬레이터 부팅 중: $IOS_SIMULATOR_PAD ($SIM_UDID)"
    xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
    open -a Simulator
    echo "시뮬레이터 부팅 대기 중..."
    for i in $(seq 1 60); do
        if flutter devices | grep -qi ipad; then
            echo "시뮬레이터 감지됨"
            break
        fi
        if [ "$i" -eq 60 ]; then
            echo "오류: iOS 시뮬레이터를 찾을 수 없습니다."
            flutter devices
            exit 1
        fi
        sleep 2
    done
fi

DEVICE_ID="$SIM_UDID"
echo "디바이스: $IOS_SIMULATOR_PAD ($DEVICE_ID)"
echo "디버그 빌드 시작..."
flutter run -d "$DEVICE_ID" --dart-define-from-file=$ENV_FILE
