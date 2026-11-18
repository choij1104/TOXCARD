import Foundation

struct Toxin: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let aka: [String]?
    let hasAntidote: Bool?
}

struct Agent: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let brands: [String]?
    let `class`: String?
    let treats: [String]?
}

struct Source: Codable, Hashable {
    let label: String
    let type: String?
}

struct Protocol_: Codable, Identifiable, Hashable {
    let id: String
    let toxinId: String
    let antidoteIds: [String]
    let tier: String
    let agentLine: String?
    let dose: String?
    let pitfall: String?
    let window: String?
    let sources: [Source]?
    let lastReviewed: String?
}

struct Toxidrome: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let onset: String?
    let pupils: String?
    let skin: String?
    let vitals: String?
    let mental: String?
    let tell: String?
    let agents: [String]?
    let search: String?
}

struct DatasetVersion: Codable {
    let version: String
    let lastReviewed: String?
    let nextReviewDue: String?
    let reviewer: String?
}

/// What the tier letter on a card means to the reader. Mirrors the dataset's own rule:
/// D = investigational or not obtainable; N = no antidote, supportive care is the treatment.
enum Availability {
    case available, notObtainable, investigational, supportive

    init(_ p: Protocol_?) {
        guard let p else { self = .supportive; return }
        switch p.tier {
        case "D": self = .investigational
        case "N": self = .supportive
        default: self = p.antidoteIds.isEmpty ? .notObtainable : .available
        }
    }

    var label: String {
        switch self {
        case .available: return "Antidote available"
        case .notObtainable: return "No obtainable antidote"
        case .investigational: return "Investigational or not obtainable"
        case .supportive: return "Supportive care"
        }
    }
}
