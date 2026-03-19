#!/bin/bash
# 공통 헬퍼 함수
# 다른 스크립트에서 source로 로드하여 사용

HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HELPERS_DIR/config.sh"

# ============================================================
# 방향키 선택 메뉴
# 사용법: select_menu "제목" "옵션1" "옵션2" ...
# 결과: MENU_RESULT 변수에 선택된 인덱스 (0부터)
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
# config.sh 초기화 (없으면 빈 설정 생성)
# ============================================================
ensure_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'CONF'
#!/bin/bash
# 디바이스 설정 파일
# iOS 시뮬레이터, Android 에뮬레이터 이름을 여기서 관리

# iOS 시뮬레이터 이름 (xcrun simctl list devices 에서 확인)
IOS_SIMULATOR_PHONE=""
IOS_SIMULATOR_PAD=""

# Android 에뮬레이터 AVD 이름 (emulator -list-avds 에서 확인)
ANDROID_AVD_PHONE=""
ANDROID_AVD_PAD=""

# 환경 변수 파일 경로 (프로젝트 루트 기준)
ENV_FILE=".env"
CONF
    fi
    source "$CONFIG_FILE"
}

# ============================================================
# config.sh에 특정 변수 값 저장
# 사용법: save_config "변수명" "값"
# ============================================================
save_config() {
    local var_name="$1"
    local var_value="$2"
    if grep -q "^${var_name}=" "$CONFIG_FILE"; then
        sed -i '' "s|^${var_name}=.*|${var_name}=\"${var_value}\"|" "$CONFIG_FILE"
    else
        echo "${var_name}=\"${var_value}\"" >> "$CONFIG_FILE"
    fi
}

# ============================================================
# iOS 시뮬레이터 선택 및 설정
# 사용법: ensure_ios_simulator "PHONE" or "PAD"
# ============================================================
ensure_ios_simulator() {
    local type="$1" # PHONE or PAD
    local var_name="IOS_SIMULATOR_${type}"
    local current_value="${!var_name}"
    local filter label

    if [ "$type" = "PHONE" ]; then
        filter="iPhone"
        label="폰"
    else
        filter="iPad"
        label="패드"
    fi

    if [ -n "$current_value" ]; then
        return 0
    fi

    echo ""
    echo "iOS ${label} 시뮬레이터가 설정되지 않았습니다."
    echo ""

    local devices=()
    while IFS= read -r line; do
        local name=$(echo "$line" | sed 's/ (.*//g' | xargs)
        [ -z "$name" ] && continue
        devices+=("$name")
    done <<< "$(xcrun simctl list devices available 2>/dev/null | grep "$filter")"

    if [ ${#devices[@]} -eq 0 ]; then
        echo "사용 가능한 iOS $label 시뮬레이터가 없습니다."
        read -p "직접 입력: " current_value
    else
        devices+=("직접 입력")
        select_menu "사용할 iOS ${label} 시뮬레이터를 선택하세요:" "${devices[@]}"

        local last_idx=$((${#devices[@]} - 1))
        if [ "$MENU_RESULT" -eq "$last_idx" ]; then
            read -p "시뮬레이터 이름 입력: " current_value
        else
            current_value="${devices[$MENU_RESULT]}"
        fi
    fi

    if [ -z "$current_value" ]; then
        echo "오류: 시뮬레이터를 선택해야 합니다."
        exit 1
    fi

    save_config "$var_name" "$current_value"
    eval "$var_name=\"$current_value\""
    echo "설정 저장됨: $var_name=$current_value"
    echo ""
}

# ============================================================
# Android 에뮬레이터 선택 및 설정
# 사용법: ensure_android_avd "PHONE" or "PAD"
# ============================================================
ensure_android_avd() {
    local type="$1" # PHONE or PAD
    local var_name="ANDROID_AVD_${type}"
    local current_value="${!var_name}"
    local label

    if [ "$type" = "PHONE" ]; then
        label="폰"
    elif [ "$type" = "PAD" ]; then
        label="패드"
    else
        label="폴드"
    fi

    if [ -n "$current_value" ]; then
        return 0
    fi

    echo ""
    echo "Android ${label} 에뮬레이터가 설정되지 않았습니다."
    echo ""

    export PATH="$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"

    local avds=()
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        avds+=("$line")
    done <<< "$(emulator -list-avds 2>/dev/null)"

    if [ ${#avds[@]} -eq 0 ]; then
        echo "사용 가능한 Android 에뮬레이터가 없습니다."
        read -p "직접 입력: " current_value
    else
        avds+=("직접 입력")
        select_menu "사용할 Android ${label} 에뮬레이터를 선택하세요:" "${avds[@]}"

        local last_idx=$((${#avds[@]} - 1))
        if [ "$MENU_RESULT" -eq "$last_idx" ]; then
            read -p "AVD 이름 입력: " current_value
        else
            current_value="${avds[$MENU_RESULT]}"
        fi
    fi

    if [ -z "$current_value" ]; then
        echo "오류: 에뮬레이터를 선택해야 합니다."
        exit 1
    fi

    save_config "$var_name" "$current_value"
    eval "$var_name=\"$current_value\""
    echo "설정 저장됨: $var_name=$current_value"
    echo ""
}
