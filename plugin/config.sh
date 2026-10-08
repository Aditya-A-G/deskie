# Deskie plugin config. Sourced by bin/send and bin/ensure-running.

# The app version this plugin installs when the app is missing or older.
DESK_BUDDY_APP_VERSION="0.1.4"

# Where releases live.
# {version} becomes e.g. 0.1.0 and {file} becomes Deskie-0.1.0-arm64.zip or SHA256SUMS.
DESK_BUDDY_RELEASE_URL="https://github.com/Aditya-A-G/deskie/releases/download/v{version}/{file}"
