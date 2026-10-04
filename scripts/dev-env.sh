# Source this file from your shell rc to set up the Flutter app dev environment.
#
# In ~/.bashrc (or ~/.zshrc):
#     source /path/to/club_client/scripts/dev-env.sh
#
# Currently configures Java 17 + the Android SDK for Flutter Android builds.
# macOS devs: adjust JAVA_HOME below to your Temurin / OpenJDK 17 install.

# Java 17 — Android Gradle Plugin requires JDK 17.
if [ -z "${JAVA_HOME:-}" ]; then
    if [ -x /usr/libexec/java_home ]; then
        # macOS
        export JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null)"
    elif [ -d /usr/lib/jvm/java-17-openjdk-amd64 ]; then
        # Ubuntu / Debian (apt openjdk-17-jdk)
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
    fi
fi

# Android SDK — adjust ANDROID_HOME if your SDK lives elsewhere.
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# Put Java + Android tools on PATH.
if [ -n "${JAVA_HOME:-}" ]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
