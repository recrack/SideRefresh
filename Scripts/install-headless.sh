#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
package_path="$repository_root/dist/SideRefreshHeadless"
configuration_path=""
enable_schedule=false
skip_build=false
executables=(
    side-refresh
    SideRefreshAgent
    SideRefreshIOSRenewal
    siderefresh-mcp
)

user_name="$(/usr/bin/id -un)"
user_home_directory="$(
    /usr/bin/dscl . -read "/Users/$user_name" NFSHomeDirectory \
        | /usr/bin/sed 's/^NFSHomeDirectory: //'
)"
if [[ "$user_home_directory" != /Users/* ]]; then
    echo "Could not resolve a safe user home directory" >&2
    exit 1
fi
install_root="$user_home_directory/Library/Application Support/SideRefresh/Headless"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            [[ $# -ge 2 ]] || {
                echo "--config requires an absolute path" >&2
                exit 2
            }
            configuration_path="$2"
            shift 2
            ;;
        --enable-schedule)
            enable_schedule=true
            shift
            ;;
        --install-root)
            [[ $# -ge 2 ]] || {
                echo "--install-root requires an absolute path" >&2
                exit 2
            }
            install_root="$2"
            shift 2
            ;;
        --skip-build)
            skip_build=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if [[ "$install_root" != /* || "$install_root" == "/" ]]; then
    echo "--install-root must be a specific absolute path" >&2
    exit 2
fi
if [[ -n "$configuration_path" && "$configuration_path" != /* ]]; then
    echo "--config must be an absolute path" >&2
    exit 2
fi

if [[ "$skip_build" == false ]]; then
    "$repository_root/Scripts/build-headless.sh"
fi
for executable in "${executables[@]}"; do
    if [[ ! -x "$package_path/bin/$executable" ]]; then
        echo "Missing headless executable: $executable" >&2
        exit 1
    fi
done

binary_install_path="$install_root/bin"
mkdir -p "$binary_install_path"
for executable in "${executables[@]}"; do
    install -m 755 \
        "$package_path/bin/$executable" \
        "$binary_install_path/$executable"
done

if [[ "$enable_schedule" == true ]]; then
    schedule_arguments=(
        schedule
        enable
        --agent
        "$binary_install_path/SideRefreshAgent"
        --confirm
    )
    if [[ -n "$configuration_path" ]]; then
        schedule_arguments+=(--config "$configuration_path")
    fi
    "$binary_install_path/side-refresh" "${schedule_arguments[@]}"
fi

echo "Installed SideRefresh Headless at:"
echo "$install_root"
echo
echo "MCP client configuration:"
echo "{"
echo "  \"mcpServers\": {"
echo "    \"siderefresh\": {"
echo "      \"command\": \"$binary_install_path/siderefresh-mcp\""
echo "    }"
echo "  }"
echo "}"
