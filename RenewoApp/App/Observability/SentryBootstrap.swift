import Foundation
import Sentry

enum SentryBootstrap {
    static func start() {
        let dsn = resolvedDsn()
        guard let dsn, !dsn.isEmpty else { return }

        let isDebug = isDebugBuild
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = isDebug ? "Debug" : "Release"
            options.enableCrashHandler = true
            options.sendDefaultPii = false
            options.tracesSampleRate = tracingSampleRate(isDebug: isDebug)
        }
    }

    private static func resolvedDsn() -> String? {
        if let envDsn = ProcessInfo.processInfo.environment["SENTRY_DSN"], !envDsn.isEmpty {
            return envDsn
        }
        return Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static func tracingSampleRate(isDebug: Bool) -> Double {
        if isDebug {
            return ProcessInfo.processInfo.environment["SENTRY_ENABLE_DEBUG_TRACING"] == "1" ? 0.1 : 0.0
        }
        return 0.1
    }
}
