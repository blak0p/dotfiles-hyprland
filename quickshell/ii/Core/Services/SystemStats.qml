import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: root

    property bool monitorActive: false
    property string sortBy: "cpu"
    property string osName: "Linux"
    property string kernel: "Loading..."
    property string hostname: "Loading..."
    property string cpuModel: "Loading..."
    property string shell: "Loading..."
    property string packages: "Loading..."
    property string packagesAur: "Loading..."
    property string username: "Loading..."
    property real cpuUsage: 0
    property string cpuTemp: "55°C"
    property string cpuFreq: "0.00 GHz"
    property string cpuCores: "4 Cores"
    property string loadAvg: "0.00 0.00 0.00"
    property real memUsage: 0
    property real memUsed: 0
    property real memTotal: 0
    property string memSizeText: "0.0 / 0.0 GiB"
    property bool hasGpu: false
    property string gpuName: "None"
    property real gpuUsage: 0
    property string gpuTemp: "0°C"
    property string gpuVram: "GPU Active"
    property string diskName: "Storage - /"
    property int diskUsage: 0
    property string diskSizeText: "0.0 / 0.0 GiB"
    property bool hasYoutubeMusic: false
    property bool hasSpotify: false
    property bool hasKew: false
    property int tasks: 0
    property string uptime: ""
    property var processList: []

    function updateDaemon() {
        let args = ["python3", Quickshell.env("HOME") + "/.config/quickshell/Scripts/get_processes.py", String(SystemInfoService.performanceInterval), root.sortBy, "--daemon"];
        if (!root.monitorActive)
            args.push("--no-processes");

        statsProc.command = args;
        statsProc.running = false;
        statsProc.running = true;
    }

    Component.onCompleted: {
        staticInfoProc.running = true;
        updateDaemon();
    }
    onMonitorActiveChanged: updateDaemon()
    onSortByChanged: updateDaemon()

    Connections {
        function onPerformanceIntervalChanged() {
            updateDaemon();
        }

        target: SystemInfoService
    }

    Process {
        id: staticInfoProc

        command: ["sh", "-c", "echo \"$(cat /etc/os-release | grep -E '^PRETTY_NAME=' | cut -d'=' -f2 | tr -d '\"')|$(uname -sr)|$(hostname)|$(cat /proc/cpuinfo | grep 'model name' | head -n1 | cut -d: -f2 | xargs)|$(getent passwd $(whoami) | cut -d: -f7 | awk -F/ '{print $NF}')|$(if command -v pacman &>/dev/null; then pacman -Qn | wc -l; else echo '0'; fi)|$(if command -v pacman &>/dev/null; then pacman -Qm | wc -l; else echo '0'; fi)|$(whoami)\""]
        onExited: (exitCode) => {
            if (exitCode === 0) {
                let parts = staticStdout.text.trim().split("|");
                if (parts.length >= 8) {
                    root.osName = parts[0];
                    root.kernel = parts[1];
                    root.hostname = parts[2];
                    root.cpuModel = parts[3];
                    root.shell = parts[4];
                    root.packages = parts[5];
                    root.packagesAur = parts[6];
                    root.username = parts[7];
                }
            }
        }

        stdout: StdioCollector {
            id: staticStdout
        }

    }

    Process {
        id: statsProc

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let parsedData = JSON.parse(data.trim());
                    root.processList = parsedData.processes || [];
                    if (parsedData.system) {
                        let sys = parsedData.system;
                        root.cpuUsage = sys.cpu_usage || 0;
                        root.memUsage = sys.mem_usage || 0;
                        root.memUsed = sys.mem_used_gb || 0;
                        root.memTotal = sys.mem_total_gb || 0;
                        root.memSizeText = root.memUsed.toFixed(1) + " / " + root.memTotal.toFixed(1) + " GiB";
                        root.tasks = sys.tasks_total || 0;
                        root.cpuTemp = sys.cpu_temp || "55°C";
                        root.uptime = sys.uptime || "";
                        root.cpuFreq = sys.cpu_freq || "N/A";
                        root.loadAvg = sys.load_avg || "0.00 0.00 0.00";
                        root.cpuCores = sys.cpu_cores || "4 Cores";
                    }
                    if (parsedData.gpu) {
                        let gpu = parsedData.gpu;
                        root.hasGpu = gpu.has_gpu || false;
                        root.gpuName = gpu.name || "None";
                        root.gpuUsage = gpu.usage || 0;
                        root.gpuTemp = gpu.temp || "0°C";
                        root.gpuVram = gpu.vram || "GPU Active";
                    }
                    if (parsedData.storage) {
                        let storage = parsedData.storage;
                        root.diskName = "Storage - " + storage.device;
                        root.diskUsage = storage.usage || 0;
                        root.diskSizeText = storage.used_gib.toFixed(1) + " / " + storage.total_gib.toFixed(1) + " GiB";
                    }
                    if (parsedData.players) {
                        let players = parsedData.players;
                        root.hasYoutubeMusic = players.has_youtube_music || false;
                        root.hasSpotify = players.has_spotify || false;
                        root.hasKew = players.has_kew || false;
                    }
                } catch (e) {
                    console.error("Error parsing stats JSON: " + e);
                }
            }
        }

    }

}
