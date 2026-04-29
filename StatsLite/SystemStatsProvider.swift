import Darwin
import Foundation
import Metal

final class SystemStatsProvider {
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    private let refreshIntervalSeconds: Int
    private let gpuName: String

    init(refreshIntervalSeconds: Int = 2) {
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.gpuName = MTLCreateSystemDefaultDevice()?.name ?? "Unavailable"
    }

    deinit {
        deallocateCPUInfo(previousCPUInfo, count: previousCPUInfoCount)
    }

    func snapshot() -> StatsSnapshot {
        StatsSnapshot(
            cpuUsagePercent: cpuUsagePercent(),
            gpuName: gpuName,
            usedMemoryBytes: usedMemoryBytes(),
            totalMemoryBytes: totalMemoryBytes(),
            refreshIntervalSeconds: refreshIntervalSeconds
        )
    }

    private func cpuUsagePercent() -> Double {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return 0
        }

        let oldCPUInfo = previousCPUInfo
        let oldCPUInfoCount = previousCPUInfoCount

        defer {
            deallocateCPUInfo(oldCPUInfo, count: oldCPUInfoCount)
            previousCPUInfo = cpuInfo
            previousCPUInfoCount = cpuInfoCount
        }

        guard let oldCPUInfo else {
            return 0
        }

        var totalUsage = 0.0

        for cpu in 0..<Int(processorCount) {
            let offset = Int(CPU_STATE_MAX) * cpu
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)] - oldCPUInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)] - oldCPUInfo[offset + Int(CPU_STATE_SYSTEM)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)] - oldCPUInfo[offset + Int(CPU_STATE_NICE)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)] - oldCPUInfo[offset + Int(CPU_STATE_IDLE)])
            let total = user + system + nice + idle

            if total > 0 {
                totalUsage += (user + system + nice) / total
            }
        }

        guard processorCount > 0 else {
            return 0
        }

        return min(max((totalUsage / Double(processorCount)) * 100, 0), 100)
    }

    private func usedMemoryBytes() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        var pageSizeValue = vm_size_t()
        let pageSizeResult = host_page_size(mach_host_self(), &pageSizeValue)
        let pageSize = pageSizeResult == KERN_SUCCESS ? UInt64(pageSizeValue) : UInt64(getpagesize())
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        return active + inactive + wired + compressed
    }

    private func totalMemoryBytes() -> UInt64 {
        var value: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &value, &size, nil, 0)
        return value
    }

    private func deallocateCPUInfo(_ info: processor_info_array_t?, count: mach_msg_type_number_t) {
        guard let info, count > 0 else {
            return
        }

        vm_deallocate(
            mach_task_self_,
            vm_address_t(UInt(bitPattern: info)),
            vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.stride)
        )
    }
}
