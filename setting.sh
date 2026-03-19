#!/bin/bash
# 디바이스 설정 스크립트
# 사용 가능한 시뮬레이터/에뮬레이터 목록에서 선택하여 config.sh를 생성/수정
# 사용법: ./scripts/setting.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"

# ============================================================
# 방향키 선택 메뉴 함수
# ============================================================
MENU_RESULT=0

select_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local count=${#options[@]}

    tput civis
    trap 'tput cnorm' RETURN

    echo "$title"
    echo ""

    while true; do
        for i in $(seq 0 $((count - 1))); do
            if [ "$i" -eq "$selected" ]; then
                echo -e "  \033[7m > ${options[$i]} \033[0m"
            else
                echo "    ${options[$i]}"
            fi
        done

        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    '[A') ((selected > 0)) && ((selected--)) ;;
                    '[B') ((selected < count - 1)) && ((selected++)) ;;
                esac
                ;;
            '')
                echo ""
                tput cnorm
                MENU_RESULT=$selected
                return 0
                ;;
        esac

        tput cuu $count
        for i in $(seq 0 $((count - 1))); do
            tput el
            tput cud1
        done
        tput cuu $count
    done
}

# ============================================================
# 현재 설정 표시
# ============================================================
show_current() {
    clear
    echo "=== 디바이스 설정 ==="
    echo ""
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "  현재 설정:"
        echo "    iOS 폰 시뮬레이터:      ${IOS_SIMULATOR_PHONE:-(미설정)}"
        echo "    iOS 패드 시뮬레이터:     ${IOS_SIMULATOR_PAD:-(미설정)}"
        echo "    Android 폰 에뮬레이터:   ${ANDROID_AVD_PHONE:-(미설정)}"
        echo "    Android 패드 에뮬레이터: ${ANDROID_AVD_PAD:-(미설정)}"
        echo "    환경변수 파일:           ${ENV_FILE:-(미설정)}"
    else
        echo "  config.sh가 없습니다. 새로 생성합니다."
    fi
    echo ""
}

# ============================================================
# iOS 시뮬레이터 선택
# ============================================================
select_ios_simulator() {
    local label="$1"  # "phone" or "pad"
    local filter="$2" # grep 필터
    local current="$3" # 현재 설정값

    local devices=()
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [ "$line" = "$current" ] && continue
        devices+=("$line")
    done <<< "$(xcrun simctl list devices available 2>/dev/null | grep -i "$filter" | sed 's/ (.*//g' | xargs -I{} echo {})"

    # 현재 선택된 디바이스를 맨 위에 추가
    if [ -n "$current" ]; then
        devices=("$current (현재)" "${devices[@]}")
    fi

    if [ ${#devices[@]} -eq 0 ]; then
        echo "사용 가능한 iOS $label 시뮬레이터가 없습니다."
        read -p "직접 입력: " SELECTED_DEVICE
        return
    fi

    devices+=("직접 입력" "건너뛰기")
    select_menu "iOS $label 시뮬레이터를 선택하세요:" "${devices[@]}"

    local last_idx=$((${#devices[@]} - 1))
    local manual_idx=$((last_idx - 1))

    if [ "$MENU_RESULT" -eq "$last_idx" ]; then
        SELECTED_DEVICE=""
    elif [ "$MENU_RESULT" -eq "$manual_idx" ]; then
        read -p "시뮬레이터 이름 입력: " SELECTED_DEVICE
    else
        SELECTED_DEVICE="${devices[$MENU_RESULT]}"
        SELECTED_DEVICE="${SELECTED_DEVICE% (현재)}"
    fi
}

# ============================================================
# Android 에뮬레이터 선택
# ============================================================
select_android_avd() {
    local label="$1"
    local current="$2" # 현재 설정값

    export PATH="$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"

    local avds=()
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [ "$line" = "$current" ] && continue
        avds+=("$line")
    done <<< "$(emulator -list-avds 2>/dev/null)"

    # 현재 선택된 에뮬레이터를 맨 위에 추가
    if [ -n "$current" ]; then
        avds=("$current (현재)" "${avds[@]}")
    fi

    if [ ${#avds[@]} -eq 0 ]; then
        echo "사용 가능한 Android 에뮬레이터가 없습니다."
        read -p "직접 입력: " SELECTED_DEVICE
        return
    fi

    avds+=("직접 입력" "건너뛰기")
    select_menu "Android $label 에뮬레이터를 선택하세요:" "${avds[@]}"

    local last_idx=$((${#avds[@]} - 1))
    local manual_idx=$((last_idx - 1))

    if [ "$MENU_RESULT" -eq "$last_idx" ]; then
        SELECTED_DEVICE=""
    elif [ "$MENU_RESULT" -eq "$manual_idx" ]; then
        read -p "AVD 이름 입력: " SELECTED_DEVICE
    else
        SELECTED_DEVICE="${avds[$MENU_RESULT]}"
        SELECTED_DEVICE="${SELECTED_DEVICE% (현재)}"
    fi
}

# ============================================================
# 메인
# ============================================================
SELECTED_DEVICE=""

# 기존 값 로드
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi
CUR_IOS_PHONE="${IOS_SIMULATOR_PHONE:-}"
CUR_IOS_PAD="${IOS_SIMULATOR_PAD:-}"
CUR_ANDROID_PHONE="${ANDROID_AVD_PHONE:-}"
CUR_ANDROID_PAD="${ANDROID_AVD_PAD:-}"
CUR_ENV="${ENV_FILE:-.env}"

show_current

# iOS 폰 시뮬레이터
select_ios_simulator "폰" "iphone" "$CUR_IOS_PHONE"
[ -n "$SELECTED_DEVICE" ] && CUR_IOS_PHONE="$SELECTED_DEVICE"

show_current
echo "  → iOS 폰: $CUR_IOS_PHONE"
echo ""

# iOS 패드 시뮬레이터
select_ios_simulator "패드" "ipad" "$CUR_IOS_PAD"
[ -n "$SELECTED_DEVICE" ] && CUR_IOS_PAD="$SELECTED_DEVICE"

show_current
echo "  → iOS 폰: $CUR_IOS_PHONE"
echo "  → iOS 패드: $CUR_IOS_PAD"
echo ""

# Android 폰 에뮬레이터
select_android_avd "폰" "$CUR_ANDROID_PHONE"
[ -n "$SELECTED_DEVICE" ] && CUR_ANDROID_PHONE="$SELECTED_DEVICE"

show_current
echo "  → iOS 폰: $CUR_IOS_PHONE"
echo "  → iOS 패드: $CUR_IOS_PAD"
echo "  → Android 폰: $CUR_ANDROID_PHONE"
echo ""

# Android 패드 에뮬레이터
select_android_avd "패드" "$CUR_ANDROID_PAD"
[ -n "$SELECTED_DEVICE" ] && CUR_ANDROID_PAD="$SELECTED_DEVICE"

# config.sh 저장
cat > "$CONFIG_FILE" << EOF
#!/bin/bash
# 디바이스 설정 파일
# iOS 시뮬레이터, Android 에뮬레이터 이름을 여기서 관리

# iOS 시뮬레이터 이름 (xcrun simctl list devices 에서 확인)
IOS_SIMULATOR_PHONE="$CUR_IOS_PHONE"
IOS_SIMULATOR_PAD="$CUR_IOS_PAD"

# Android 에뮬레이터 AVD 이름 (emulator -list-avds 에서 확인)
ANDROID_AVD_PHONE="$CUR_ANDROID_PHONE"
ANDROID_AVD_PAD="$CUR_ANDROID_PAD"

# 환경 변수 파일 경로 (프로젝트 루트 기준)
ENV_FILE="$CUR_ENV"
EOF

clear
echo "=== 설정 완료 ==="
echo ""
echo "  iOS 폰 시뮬레이터:      $CUR_IOS_PHONE"
echo "  iOS 패드 시뮬레이터:     $CUR_IOS_PAD"
echo "  Android 폰 에뮬레이터:   $CUR_ANDROID_PHONE"
echo "  Android 패드 에뮬레이터: $CUR_ANDROID_PAD"
echo "  환경변수 파일:           $CUR_ENV"
echo ""
echo "  저장됨: scripts/config.sh"
echo ""
