import Foundation
import SwiftData

enum ApplicationStatus: String, Codable, CaseIterable, Hashable {
    case wishlist = "Wishlist"
    case applied = "Applied"
    case hrScreen = "HR Screen"
    case technicalInterview = "Technical Interview"
    case finalInterview = "Final Interview"
    case offer = "Offer"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case withdrawn = "Withdrawn"

    var isTerminal: Bool {
        self == .accepted || self == .rejected || self == .withdrawn
    }

    var isPipelineStage: Bool {
        !isTerminal
    }

    var columnOrder: Int {
        switch self {
        case .wishlist: return 0
        case .applied: return 1
        case .hrScreen: return 2
        case .technicalInterview: return 3
        case .finalInterview: return 4
        case .offer: return 5
        case .accepted: return 6
        case .rejected: return 7
        case .withdrawn: return 8
        }
    }

    var color: String {
        switch self {
        case .wishlist: return "gray"
        case .applied: return "blue"
        case .hrScreen: return "purple"
        case .technicalInterview: return "orange"
        case .finalInterview: return "yellow"
        case .offer: return "green"
        case .accepted: return "mint"
        case .rejected: return "red"
        case .withdrawn: return "brown"
        }
    }
}

enum WorkType: String, Codable, CaseIterable, Hashable {
    case remote = "Remote"
    case hybrid = "Hybrid"
    case onsite = "Onsite"
}

@Model
final class JobApplication {
    var id: UUID
    var company: String
    var role: String
    var statusRaw: String
    var location: String
    var workTypeRaw: String
    var salaryMin: Int
    var salaryMax: Int
    var notes: String
    var dateAdded: Date
    var lastUpdated: Date

    var status: ApplicationStatus {
        get { ApplicationStatus(rawValue: statusRaw) ?? .wishlist }
        set { statusRaw = newValue.rawValue; lastUpdated = Date() }
    }

    var workType: WorkType {
        get { WorkType(rawValue: workTypeRaw) ?? .remote }
        set { workTypeRaw = newValue.rawValue; lastUpdated = Date() }
    }

    var isPriority: Bool {
        location.localizedCaseInsensitiveContains("Hamburg") || workType == .remote
    }

    var hasSalary: Bool {
        salaryMin > 0 || salaryMax > 0
    }

    var salaryDisplay: String {
        guard hasSalary else { return "—" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        fmt.currencySymbol = "€"
        let lo = fmt.string(from: NSNumber(value: salaryMin)) ?? "\(salaryMin)"
        let hi = fmt.string(from: NSNumber(value: salaryMax)) ?? "\(salaryMax)"
        if salaryMin == salaryMax { return lo }
        return "\(lo) – \(hi)"
    }

    init(
        company: String = "",
        role: String = "",
        status: ApplicationStatus = .wishlist,
        location: String = "",
        workType: WorkType = .remote,
        salaryMin: Int = 0,
        salaryMax: Int = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.company = company
        self.role = role
        self.statusRaw = status.rawValue
        self.location = location
        self.workTypeRaw = workType.rawValue
        self.salaryMin = salaryMin
        self.salaryMax = salaryMax
        self.notes = notes
        self.dateAdded = Date()
        self.lastUpdated = Date()
    }
}
