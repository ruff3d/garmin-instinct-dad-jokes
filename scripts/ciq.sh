#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
sdk="${CONNECTIQ_SDK:-$project_dir/.tools/sdk}"
key="${CIQ_DEVELOPER_KEY:-$project_dir/.tools/developer_key.der}"
device=instinct3solar45mm
mode="${1:-build}"

if [[ "$mode" == "regenerate-app-id" ]]; then
    app_id="$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')"
    tmp_manifest="$(mktemp)"
    sed -E "s/(<iq:application id=\")[^\"]+/\1$app_id/" manifest.xml > "$tmp_manifest"
    mv "$tmp_manifest" manifest.xml
    echo "Regenerated app ID: $app_id"
    exit 0
fi

if [[ -z "${JAVA_HOME:-}" ]]; then
    for candidate in "$project_dir"/.tools/jdk-*/Contents/Home; do
        if [[ -x "$candidate/bin/java" ]]; then
            export JAVA_HOME="$candidate"
            break
        fi
    done
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

if [[ ! -f "$sdk/bin/monkeybrains.jar" ]]; then
    echo "Set CONNECTIQ_SDK to your extracted Garmin Connect IQ SDK directory." >&2
    exit 1
fi

case "$mode" in
    simulator)
        exec "$sdk/bin/connectiq"
        ;;
    run)
        exec "$sdk/bin/monkeydo" "$project_dir/bin/DadJokes.prg" "$device"
        ;;
    run-tests)
        exec "$sdk/bin/monkeydo" "$project_dir/bin/DadJokes-tests.prg" "$device" -t
        ;;
    install)
        watch="${GARMIN_VOLUME:-/Volumes/GARMIN}"
        if [[ ! -d "$watch/GARMIN/APPS" ]]; then
            echo "Connect the watch by USB and confirm $watch/GARMIN/APPS exists (set GARMIN_VOLUME to override)." >&2
            exit 1
        fi
        bash "$0" build
        cp "$project_dir/bin/DadJokes.prg" "$watch/GARMIN/APPS/DadJokes.prg"
        sync
        echo "Copied to $watch/GARMIN/APPS/DadJokes.prg. Eject the watch, then find Dad Jokes in the app list."
        exit 0
        ;;
    build|test|check) ;;
    *)
        echo "Usage: bash scripts/ciq.sh {build|test|check|simulator|run|run-tests|install|regenerate-app-id}" >&2
        exit 2
        ;;
esac

if [[ ! -f "$key" ]]; then
    echo "Set CIQ_DEVELOPER_KEY to your Garmin developer .der key. See README.md." >&2
    exit 1
fi
mkdir -p bin
args=(-f monkey.jungle -y "$key" -w -l 3)
case "$mode" in
    build) args+=(-d "$device" -r -o bin/DadJokes.prg) ;;
    test) args+=(-d "$device" -t -o bin/DadJokes-tests.prg) ;;
    check)
        echo "Generic API/type check only; this does not create a watch-installable build."
        args+=(-t -o bin/DadJokes-generic-check.prg)
        ;;
esac
exec java -Djava.awt.headless=true -jar "$sdk/bin/monkeybrains.jar" "${args[@]}"
