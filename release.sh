#!/bin/bash
# 릴리즈 빌드 및 설치 스크립트
# 사용법: ./scripts/release.sh

set -e

# 디바이스 설정 로드
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

if [ ! -f "$ENV_FILE" ]; then
    echo "오류: $ENV_FILE 파일이 없습니다."
    exit 1
fi

# ============================================================
# 방향키 선택 메뉴 함수
# 사용법: select_menu "제목" "옵션1" "옵션2" ...
# 결과: MENU_RESULT 변수에 선택된 인덱스 (0부터)
# ============================================================
# ============================================================
# 로딩 애니메이션 함수
# 사용법: start_loading "메시지" → 작업 → stop_loading
# ============================================================
LOADING_PID=""

start_loading() {
    local msg="$1"
    (
        local dots=("." ".." "...")
        local i=0
        while true; do
            printf "\r%s%s   " "$msg" "${dots[$i]}"
            i=$(( (i + 1) % 3 ))
            sleep 0.4
        done
    ) &
    LOADING_PID=$!
}

stop_loading() {
    if [ -n "$LOADING_PID" ]; then
        kill "$LOADING_PID" 2>/dev/null
        wait "$LOADING_PID" 2>/dev/null || true
        LOADING_PID=""
        printf "\r\033[K"
    fi
}

MENU_RESULT=0

select_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local count=${#options[@]}

    # 커서 숨기기
    tput civis

    # 종료 시 커서 복원
    trap 'tput cnorm' RETURN

    echo "$title"
    echo ""

    while true; do
        # 메뉴 출력
        for i in $(seq 0 $((count - 1))); do
            if [ "$i" -eq "$selected" ]; then
                echo -e "  \033[7m > ${options[$i]} \033[0m"
            else
                echo "    ${options[$i]}"
            fi
        done

        # 키 입력 읽기
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    '[A') # 위쪽 방향키
                        ((selected > 0)) && ((selected--))
                        ;;
                    '[B') # 아래쪽 방향키
                        ((selected < count - 1)) && ((selected++))
                        ;;
                esac
                ;;
            '') # 엔터
                echo ""
                tput cnorm
                MENU_RESULT=$selected
                return 0
                ;;
        esac

        # 메뉴 영역만 지우고 다시 그리기
        tput cuu $count
        for i in $(seq 0 $((count - 1))); do
            tput el
            tput cud1
        done
        tput cuu $count
    done
}

# 선택 경로를 표시하는 함수
# 사용법: show_header "Android" "APK 빌드"
show_header() {
    clear
    echo "=== 릴리즈 빌드 ==="
    echo ""
    local path=""
    for item in "$@"; do
        if [ -n "$path" ]; then
            path="$path > $item"
        else
            path="$item"
        fi
    done
    if [ -n "$path" ]; then
        echo "  $path"
    fi
    echo ""
    echo ""
}

# ============================================================
# 메인 루프
# ============================================================
# scripts/ 폴더의 부모 = 프로젝트 루트 절대 경로
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PLATFORM_NAMES=("Android" "iOS")
ANDROID_TARGETS=("연결된 실기기에 설치" "APK 빌드" "뒤로가기")
IOS_TARGETS=("연결된 실기기에 설치" "IPA 빌드" "뒤로가기")

while true; do
    show_header
    select_menu "플랫폼을 선택하세요:" "${PLATFORM_NAMES[@]}"
    PLATFORM=$MENU_RESULT
    PLATFORM_NAME="${PLATFORM_NAMES[$PLATFORM]}"

    # ============================================================
    # Android
    # ============================================================
    if [ "$PLATFORM" -eq 0 ]; then
        export PATH="$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"

        show_header "$PLATFORM_NAME"
        select_menu "설치 대상을 선택하세요:" "${ANDROID_TARGETS[@]}"
        CHOICE=$MENU_RESULT

        # 뒤로가기
        if [ "$CHOICE" -eq 2 ]; then
            continue
        fi

        TARGET_NAME="${ANDROID_TARGETS[$CHOICE]}"
        show_header "$PLATFORM_NAME" "$TARGET_NAME"

        case $CHOICE in
            0)
                # 연결된 Android 실기기 목록 가져오기
                start_loading "연결된 기기 검색 중"
                DEVICE_LINES=()
                DEVICE_NAMES=()
                while IFS= read -r line; do
                    [ -z "$line" ] && continue
                    local_id=$(echo "$line" | awk '{print $1}')
                    local_model=$(adb -s "$local_id" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
                    [ -z "$local_model" ] && local_model="$local_id"
                    DEVICE_LINES+=("$local_id")
                    DEVICE_NAMES+=("$local_model ($local_id)")
                done <<< "$(adb devices 2>/dev/null | grep -v "^List" | grep -v "^$" | grep -v "emulator")"
                stop_loading

                if [ ${#DEVICE_LINES[@]} -eq 0 ]; then
                    echo "오류: USB로 연결된 Android 기기를 찾을 수 없습니다."
                    exit 1
                fi

                DEVICE_NAMES+=("뒤로가기")
                show_header "$PLATFORM_NAME" "$TARGET_NAME"
                select_menu "기기를 선택하세요:" "${DEVICE_NAMES[@]}"
                DEV_CHOICE=$MENU_RESULT

                # 뒤로가기
                if [ "$DEV_CHOICE" -eq ${#DEVICE_LINES[@]} ]; then
                    continue 2
                fi

                DEVICE_ID="${DEVICE_LINES[$DEV_CHOICE]}"
                show_header "$PLATFORM_NAME" "$TARGET_NAME" "${DEVICE_NAMES[$DEV_CHOICE]}"
                echo "릴리즈 빌드 및 설치 시작..."
                flutter run -d "$DEVICE_ID" --release --dart-define-from-file=$ENV_FILE
                ;;
            1)
                APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
                DEFAULT_SAVE="$PROJECT_ROOT"
                read -p "저장 경로: $DEFAULT_SAVE" INPUT_PATH
                SAVE_PATH="${INPUT_PATH:-$DEFAULT_SAVE}"
                echo ""
                echo "릴리즈 APK 빌드 시작..."
                flutter build apk --dart-define-from-file=$ENV_FILE
                echo ""
                mkdir -p "$SAVE_PATH"
                cp "$APK_SOURCE" "$SAVE_PATH/app-release.apk"
                echo "빌드 완료! APK 복사됨:"
                echo "  $SAVE_PATH/app-release.apk"
                ;;
        esac
        break

    # ============================================================
    # iOS
    # ============================================================
    elif [ "$PLATFORM" -eq 1 ]; then

        show_header "$PLATFORM_NAME"
        select_menu "설치 대상을 선택하세요:" "${IOS_TARGETS[@]}"
        CHOICE=$MENU_RESULT

        # 뒤로가기
        if [ "$CHOICE" -eq 2 ]; then
            continue
        fi

        TARGET_NAME="${IOS_TARGETS[$CHOICE]}"
        show_header "$PLATFORM_NAME" "$TARGET_NAME"

        case $CHOICE in
            0)
                # 연결된 iOS 실기기 목록 가져오기
                start_loading "연결된 기기 검색 중"
                DEVICE_LINES=()
                DEVICE_NAMES=()
                while IFS= read -r line; do
                    [ -z "$line" ] && continue
                    local_id=$(echo "$line" | awk -F'•' '{print $2}' | xargs)
                    local_name=$(echo "$line" | awk -F'•' '{print $1}' | xargs)
                    [ -z "$local_id" ] && continue
                    DEVICE_LINES+=("$local_id")
                    DEVICE_NAMES+=("$local_name ($local_id)")
                done <<< "$(flutter devices | grep -i "ios\|iphone\|ipad" | grep -iv "simulator")"
                stop_loading

                if [ ${#DEVICE_LINES[@]} -eq 0 ]; then
                    echo "오류: USB로 연결된 iOS 기기를 찾을 수 없습니다."
                    exit 1
                fi

                DEVICE_NAMES+=("뒤로가기")
                show_header "$PLATFORM_NAME" "$TARGET_NAME"
                select_menu "기기를 선택하세요:" "${DEVICE_NAMES[@]}"
                DEV_CHOICE=$MENU_RESULT

                # 뒤로가기
                if [ "$DEV_CHOICE" -eq ${#DEVICE_LINES[@]} ]; then
                    continue 2
                fi

                DEVICE_ID="${DEVICE_LINES[$DEV_CHOICE]}"
                show_header "$PLATFORM_NAME" "$TARGET_NAME" "${DEVICE_NAMES[$DEV_CHOICE]}"
                echo "릴리즈 빌드 및 설치 시작..."
                flutter run -d "$DEVICE_ID" --release --dart-define-from-file=$ENV_FILE
                ;;
            1)
                IPA_SOURCE="build/ios/ipa"
                DEFAULT_SAVE="$PROJECT_ROOT"
                read -p "저장 경로: $DEFAULT_SAVE" INPUT_PATH
                SAVE_PATH="${INPUT_PATH:-$DEFAULT_SAVE}"
                echo ""
                echo "릴리즈 IPA 빌드 시작..."
                flutter build ipa --dart-define-from-file=$ENV_FILE
                echo ""
                mkdir -p "$SAVE_PATH"
                cp "$IPA_SOURCE"/*.ipa "$SAVE_PATH/"
                echo "빌드 완료! IPA 복사됨:"
                echo "  $SAVE_PATH/"
                ;;
        esac
        break
    fi
done
