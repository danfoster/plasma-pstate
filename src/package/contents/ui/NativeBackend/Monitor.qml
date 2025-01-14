import QtQuick 2.3
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/utils.js' as Utils
import '../../code/datasource.js' as Ds


Item {
    id: nativeMonitor
    property string name: "NativeMonitor"
    property var args: ['-read-all']

    signal handleReadResult(var args, string stdout)
    signal handleReadAvailResult(string stdout)
    signal handleSetValueResult(var arg, string stdout)

    //
    // proxy the inner timer object
    //
    function start() { timer.start() }
    function stop() { timer.stop() }
    function restart() { timer.restart() }

    property alias interval: timer.interval
    property alias running: timer.running
    property alias repeat: timer.repeat
    property alias triggeredOnStart: timer.triggeredOnStart


    function init() {
        plasmoid.nativeInterface.setPrefs(['-read-available'])
        start()
    }

    Timer {
        id: timer
        onTriggered: {
            plasmoid.nativeInterface.setPrefs(args)
        }
    }

    function dataSourceReady() {
        var detectedSensors = main.sensorsMgr.detectedSensors
        var readable = Ds.filterReadableSensors(detectedSensors)
        args = ['-read-some'].concat(readable)
    }

    Connections {
        target: plasmoid.nativeInterface

        function debugPrint(data) {
            var obj = JSON.parse(data.stdout)
            var keys = Object.keys(obj)
            for (var i=0; i< keys.length; i++) {
                print(keys[i], " = ", obj[keys[i]])
            }
        }

        onCommandFinished: {
            var exitCode = data.exitCode
            var args = data.args

            if (exitCode !== 0) {
                print('error: ' + data.stderr)
                notificationSource.createNotification('error: ' + data.stderr)
                return
            }

            if (args.length === 0) {
                print('error: Command result with no args.')
                return
            }

            if (args[0] === '-read-all' || args[0] === '-read-some') {
                handleReadResult(args, data.stdout)
                return
            }

            if (args[0] === '-read-available') {
                handleReadAvailResult(data.stdout)
                return
            }

            if (args[0] === '-write-sensor') {
                handleSetValueResult(args[1], data.stdout)
            }
        }
    }
}
