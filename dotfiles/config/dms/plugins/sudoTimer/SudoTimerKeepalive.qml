import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services

QtObject {
    id: root

    property string pluginId: "sudoTimer"
    property var pluginService: null
    property var popoutService: null

    // State mirrored from the sudo-timer script
    property bool active: false
    property int remainingSec: 0

    readonly property string scriptPath: "__HOME__/.local/bin/sudo-timer"

    function humanRemaining() {
        const mins = Math.max(0, Math.round(remainingSec / 60));
        if (mins >= 60)
            return Math.floor(mins / 60) + "h " + (mins % 60) + "m";
        return mins + " min";
    }

    function tick() {
        if (tickProc.running)
            return;
        tickProc.running = true;
    }

    function handleTickLine(line) {
        const out = line.trim();
        if (out === "")
            return;

        let activeNow = false;
        let expired = false;

        if (out.startsWith("active ")) {
            root.remainingSec = parseInt(out.split(" ")[1]) || 0;
            activeNow = true;
        } else if (out === "expired") {
            expired = true;
        }

        // Toast only on state transitions — no notification spam.
        if (activeNow && !root.active) {
            ToastService.showInfo("Sudo Timer", "Passwordless sudo active — " + root.humanRemaining() + " remaining");
        } else if (!activeNow && root.active) {
            if (expired)
                ToastService.showError("Sudo Timer expired", "Passwordless sudo ended. Sudo requires a password again.");
            else
                ToastService.showError("Sudo Timer", "Sudo timestamp lost — press Mod+Shift+S to re-authenticate.");
        }

        root.active = activeNow;
    }

    property Process tickProc: Process {
        command: ["/bin/sh", "-c", root.scriptPath + " tick"]

        stdout: SplitParser {
            onRead: line => root.handleTickLine(line)
        }
    }

    property Timer tickTimer: Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: {
            root.tick();
            if (interval === 1000)
                interval = 300000;
        }
    }

    Component.onCompleted: {
        console.info("SudoTimer daemon started — ticking every 5 min");
    }
}
