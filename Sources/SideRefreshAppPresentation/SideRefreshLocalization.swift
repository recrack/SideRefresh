import Foundation

public enum SideRefreshLanguagePreference:
    String,
    CaseIterable,
    Hashable,
    Identifiable,
    Sendable
{
    case system
    case korean = "ko"
    case english = "en"

    public var id: String { rawValue }

    public var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .korean:
            return "ko"
        case .english:
            return "en"
        }
    }

    public func locale(fallingBackTo fallback: Locale) -> Locale {
        localeIdentifier.map { Locale(identifier: $0) } ?? fallback
    }
}

public enum SideRefreshLocalizedArgument:
    Equatable,
    Sendable
{
    case integer(Int)
    case localizedKey(String)
    indirect case localizedText(SideRefreshLocalizedText)
    case verbatim(String)
}

public struct SideRefreshLocalizedText:
    Equatable,
    Sendable
{
    public let source: String
    public let arguments: [SideRefreshLocalizedArgument]
    public let isVerbatim: Bool

    public static func key(_ source: String) -> Self {
        Self(source: source, arguments: [], isVerbatim: false)
    }

    public static func format(
        _ source: String,
        _ arguments: SideRefreshLocalizedArgument...
    ) -> Self {
        Self(
            source: source,
            arguments: arguments,
            isVerbatim: false
        )
    }

    public static func verbatim(_ value: String) -> Self {
        Self(source: value, arguments: [], isVerbatim: true)
    }

    public func resolved(
        language suppliedLanguage: SideRefreshLanguagePreference? = nil,
        bundle: Bundle = .main
    ) -> String {
        guard !isVerbatim else {
            return source
        }
        let language = suppliedLanguage
            ?? SideRefreshLocalization.languagePreference()
        let localizedSource = SideRefreshLocalization.string(
            source,
            language: language,
            bundle: bundle
        )
        guard !arguments.isEmpty else {
            return localizedSource
        }
        let renderedArguments: [CVarArg] = arguments.map { argument in
            switch argument {
            case .integer(let value):
                return value
            case .localizedKey(let key):
                return SideRefreshLocalization.string(
                    key,
                    language: language,
                    bundle: bundle
                )
            case .localizedText(let text):
                return text.resolved(
                    language: language,
                    bundle: bundle
                )
            case .verbatim(let value):
                return value
            }
        }
        return String(
            format: localizedSource,
            locale: language.locale(
                fallingBackTo: Locale.autoupdatingCurrent
            ),
            arguments: renderedArguments
        )
    }
}

public enum SideRefreshLocalization {
    public static let preferenceKey = "side-refresh.language"

    public static func languagePreference(
        in defaults: UserDefaults = .standard
    ) -> SideRefreshLanguagePreference {
        defaults.string(forKey: preferenceKey)
            .flatMap(SideRefreshLanguagePreference.init(rawValue:))
            ?? .system
    }

    public static func setLanguagePreference(
        _ preference: SideRefreshLanguagePreference,
        in defaults: UserDefaults = .standard
    ) {
        defaults.set(preference.rawValue, forKey: preferenceKey)
    }

    public static func string(
        _ source: String,
        bundle: Bundle = .main
    ) -> String {
        string(
            source,
            language: languagePreference(),
            bundle: bundle
        )
    }

    public static func string(
        _ source: String,
        language: SideRefreshLanguagePreference,
        bundle: Bundle = .main
    ) -> String {
        let localizationBundle = resourceBundle(
            for: language,
            in: bundle
        )
        return localizationBundle.localizedString(
            forKey: source,
            value: source,
            table: nil
        )
    }

    public static func format(
        _ source: String,
        _ arguments: CVarArg...,
        bundle: Bundle = .main
    ) -> String {
        let language = languagePreference()
        return String(
            format: string(
                source,
                language: language,
                bundle: bundle
            ),
            locale: language.locale(
                fallingBackTo: Locale.current
            ),
            arguments: arguments
        )
    }

    public static func date(
        _ date: Date,
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style,
        language: SideRefreshLanguagePreference? = nil,
        timeZone: TimeZone? = nil
    ) -> String {
        let language = language ?? languagePreference()
        let formatter = DateFormatter()
        formatter.locale = language.locale(
            fallingBackTo: Locale.autoupdatingCurrent
        )
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        if let timeZone {
            formatter.timeZone = timeZone
        }
        return formatter.string(from: date)
    }

    private static func resourceBundle(
        for language: SideRefreshLanguagePreference,
        in bundle: Bundle
    ) -> Bundle {
        guard let languageCode = language.localeIdentifier,
              let url = bundle.url(
                forResource: languageCode,
                withExtension: "lproj"
              ),
              let localizedBundle = Bundle(url: url)
        else {
            return bundle
        }
        return localizedBundle
    }
}
