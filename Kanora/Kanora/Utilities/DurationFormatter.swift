import Foundation

enum DurationFormatter {
    static func string(from seconds: TimeInterval, locale: Locale = .current) -> String {
        let sanitizedSeconds = max(0, seconds)
        #if os(Linux)
        return formatUsingDuration(sanitizedSeconds, locale: locale)
        #else
        if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
            return formatUsingDuration(sanitizedSeconds, locale: locale)
        } else {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = [.pad]
            formatter.allowedUnits = sanitizedSeconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
            formatter.calendar = locale.calendar
            formatter.locale = locale
            return formatter.string(from: sanitizedSeconds) ?? ""
        }
        #endif
    }

    private static func formatUsingDuration(_ seconds: TimeInterval, locale: Locale) -> String {
        let pattern: Duration.TimeFormatStyle.Pattern = seconds >= 3600 ? .hourMinuteSecond : .minuteSecond
        var style = Duration.TimeFormatStyle(pattern: pattern)
        style.locale = locale
        return Duration.seconds(Int64(seconds.rounded())).formatted(style)
    }
}
