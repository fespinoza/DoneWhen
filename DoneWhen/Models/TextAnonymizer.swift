import Foundation

// I won't care about this code
// It's AI slop, quick and dirty to help me demo the app and anonymize personal information

struct TextAnonymizer {
    enum ConfigurationError: Error {
        case invalidEntry
        case duplicateKey
    }

    private let keys: [String]
    private let replacements: [String: String]

    init(data: Data) throws {
        try self.init(dictionary: JSONDecoder().decode([String: String].self, from: data))
    }

    init(dictionary: [String: String]) throws {
        let keys = dictionary.keys.sorted {
            $0.count == $1.count ? $0 < $1 : $0.count > $1.count
        }
        var seen: [String] = []
        for key in keys {
            guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let replacement = dictionary[key],
                  !replacement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ConfigurationError.invalidEntry
            }
            guard !seen.contains(where: {
                $0.compare(key, options: .caseInsensitive, locale: Locale(identifier: "en_US_POSIX")) == .orderedSame
            }) else {
                throw ConfigurationError.duplicateKey
            }
            seen.append(key)
        }
        self.keys = keys
        replacements = dictionary
    }

    static func load(bundle: Bundle = .main) throws -> TextAnonymizer {
        guard let url = bundle.url(forResource: "Anonymization", withExtension: "json") else {
            return try TextAnonymizer(dictionary: [:])
        }
        return try TextAnonymizer(data: Data(contentsOf: url))
    }

    func anonymize(_ text: String) -> String {
        guard !replacements.isEmpty else { return text }
        let scalars = text.unicodeScalars
        func isWordCharacter(at index: String.Index) -> Bool {
            let scalar = scalars[index]
            switch scalar.properties.generalCategory {
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
                 .nonspacingMark, .spacingMark, .enclosingMark,
                 .decimalNumber, .letterNumber, .otherNumber:
                return true
            default:
                return scalar == "_"
            }
        }

        var result = ""
        var position = text.startIndex
        while position < text.endIndex {
            let startsWord = position == text.startIndex
                || !isWordCharacter(at: scalars.index(before: position))
            var matchedRange: Range<String.Index>?
            var replacement: String?
            if startsWord {
                // Keys are longest first. Match only original text so replacements never cascade.
                for key in keys {
                    guard let range = text.range(
                        of: key, options: [.anchored, .caseInsensitive],
                        range: position..<text.endIndex,
                        locale: Locale(identifier: "en_US_POSIX")
                    ),
                    range.upperBound == text.endIndex || !isWordCharacter(at: range.upperBound) else {
                        continue
                    }
                    matchedRange = range
                    replacement = replacements[key]
                    break
                }
            }
            if let matchedRange, let replacement {
                result += replacement
                position = matchedRange.upperBound
            } else {
                let next = scalars.index(after: position)
                result += text[position..<next]
                position = next
            }
        }
        return result
    }
}

enum Anonymization {
    static let preferenceKey = "anonymizeData"
    static let configuration = Result { try TextAnonymizer.load() }

    static var isAvailable: Bool {
        if case .success = configuration { return true }
        return false
    }

    static func displayName(_ name: String, enabled: Bool) -> String {
        guard enabled, case let .success(anonymizer) = configuration else { return name }
        return anonymizer.anonymize(name)
    }
}
