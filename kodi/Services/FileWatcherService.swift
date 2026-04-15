import Foundation

private let fileWatcherIgnoredSegments: [String] = [
    "/node_modules/", "/.build/", "/DerivedData/", "/.next/",
    "/target/", "/dist/", "/.venv/", "/__pycache__/", "/.gradle/",
    "/.dart_tool/", "/Pods/"
]

private func isIgnoredBuildDirectory(_ path: String) -> Bool {
    for segment in fileWatcherIgnoredSegments {
        if path.contains(segment) { return true }
    }
    return false
}

@Observable
final class FileWatcherService {
    private var streams: [URL: FSEventStreamRef] = [:]
    private var debounceWorkItems: [URL: DispatchWorkItem] = [:]
    var onChange: ((URL, _ branchChanged: Bool) -> Void)?

    func watch(directory: URL) {
        guard streams[directory] == nil else { return }

        let pathString = directory.path as CFString
        let pathsToWatch = [pathString] as CFArray

        var context = FSEventStreamContext()
        let unmanagedSelf = Unmanaged.passUnretained(self)
        context.info = unmanagedSelf.toOpaque()

        let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<FileWatcherService>.fromOpaque(info).takeUnretainedValue()
            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]

            var sawBranchChange = false
            let relevantChanges = paths.filter { path in
                // Allow HEAD and refs/heads/* through so we can detect CLI branch switches,
                // but drop all other .git/ internals (objects, index, logs, etc.).
                if path.contains("/.git/") {
                    if path.contains("/.git/HEAD") || path.contains("/.git/refs/heads/") {
                        sawBranchChange = true
                        return true
                    }
                    return false
                }
                return !isIgnoredBuildDirectory(path)
            }

            guard !relevantChanges.isEmpty else { return }

            for (watchedURL, _) in watcher.streams {
                let watchedPath = watchedURL.path
                if relevantChanges.contains(where: { $0.hasPrefix(watchedPath) }) {
                    watcher.debouncedNotify(for: watchedURL, branchChanged: sawBranchChange)
                    break
                }
            }
        }

        guard let stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // 500ms latency for debouncing
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        ) else { return }

        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
        streams[directory] = stream
    }

    func unwatch(directory: URL) {
        guard let stream = streams.removeValue(forKey: directory) else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        debounceWorkItems[directory]?.cancel()
        debounceWorkItems.removeValue(forKey: directory)
    }

    func unwatchAll() {
        for (url, _) in streams {
            unwatch(directory: url)
        }
    }

    private func debouncedNotify(for url: URL, branchChanged: Bool) {
        debounceWorkItems[url]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.onChange?(url, branchChanged)
        }
        debounceWorkItems[url] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    deinit {
        for (_, stream) in streams {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}
