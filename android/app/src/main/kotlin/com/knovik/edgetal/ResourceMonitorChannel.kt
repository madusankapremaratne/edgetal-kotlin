package com.knovik.edgetal

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Native side of the `edgetal/resource_monitor` channel — on-device
 * memory / battery / CPU / thermal sampling for the paper's computational
 * resource analysis. Every value is read from public, no-permission-required
 * Android APIs; where a metric genuinely isn't available (e.g. thermal status
 * below API 29), the sample says so explicitly rather than guessing.
 */
class ResourceMonitorChannel(private val context: Context) {

    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val activityManager =
        context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    private val batteryManager =
        context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    private val powerManager =
        context.getSystemService(Context.POWER_SERVICE) as PowerManager

    // Baseline for the per-app CPU% delta between consecutive samples.
    private var lastCpuTimeMs: Long? = null
    private var lastWallTimeMs: Long? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "edgetal/resource_monitor").setMethodCallHandler { call, result ->
            when (call.method) {
                "sample" -> executor.execute {
                    val snapshot = try {
                        sample()
                    } catch (e: Exception) {
                        main.post { result.error("SAMPLE_FAILED", e.message, null) }
                        return@execute
                    }
                    main.post { result.success(snapshot) }
                }
                "reset" -> executor.execute {
                    lastCpuTimeMs = null
                    lastWallTimeMs = null
                    main.post { result.success(null) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sample(): Map<String, Any?> {
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)

        val pssKb = activityManager
            .getProcessMemoryInfo(intArrayOf(Process.myPid()))
            .firstOrNull()
            ?.totalPss ?: 0

        val batteryPct = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val batteryCurrentUa =
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        val batteryChargeCounterUah =
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)

        val batteryStatusIntent = context.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        )
        val status = batteryStatusIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL

        val cpuAppPct = computeCpuPercent()

        val thermalStatus = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            thermalStatusLabel(powerManager.currentThermalStatus)
        } else {
            "UNSUPPORTED"
        }

        return mapOf(
            "memPssMb" to pssKb / 1024.0,
            "memAvailMb" to memInfo.availMem / (1024.0 * 1024.0),
            "memTotalMb" to memInfo.totalMem / (1024.0 * 1024.0),
            "lowMemory" to memInfo.lowMemory,
            "batteryPct" to batteryPct,
            "batteryCurrentUa" to batteryCurrentUa,
            "batteryChargeCounterUah" to batteryChargeCounterUah,
            "charging" to charging,
            "cpuAppPct" to cpuAppPct,
            "thermalStatus" to thermalStatus,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
        )
    }

    /**
     * Per-app CPU utilisation % since the previous sample, normalised by core
     * count. Uses [Process.getElapsedCpuTime] (cumulative utime+stime in ms)
     * rather than hand-parsing /proc/self/stat, which varies across OEM
     * kernels (e.g. MIUI on the Redmi Note 7).
     */
    private fun computeCpuPercent(): Double {
        val cpuTimeMs = Process.getElapsedCpuTime()
        val wallTimeMs = System.currentTimeMillis()

        val prevCpu = lastCpuTimeMs
        val prevWall = lastWallTimeMs
        lastCpuTimeMs = cpuTimeMs
        lastWallTimeMs = wallTimeMs

        if (prevCpu == null || prevWall == null) return 0.0
        val wallDelta = wallTimeMs - prevWall
        if (wallDelta <= 0) return 0.0
        val cpuDelta = cpuTimeMs - prevCpu
        val cores = Runtime.getRuntime().availableProcessors().coerceAtLeast(1)
        return (cpuDelta.toDouble() / wallDelta.toDouble() / cores) * 100.0
    }

    private fun thermalStatusLabel(status: Int): String = when (status) {
        PowerManager.THERMAL_STATUS_NONE -> "NONE"
        PowerManager.THERMAL_STATUS_LIGHT -> "LIGHT"
        PowerManager.THERMAL_STATUS_MODERATE -> "MODERATE"
        PowerManager.THERMAL_STATUS_SEVERE -> "SEVERE"
        PowerManager.THERMAL_STATUS_CRITICAL -> "CRITICAL"
        PowerManager.THERMAL_STATUS_EMERGENCY -> "EMERGENCY"
        PowerManager.THERMAL_STATUS_SHUTDOWN -> "SHUTDOWN"
        else -> "UNKNOWN"
    }
}
