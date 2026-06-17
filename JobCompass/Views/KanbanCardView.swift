import SwiftUI

struct KanbanCardView: View {
    let application: JobApplication
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(application.company)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(application.role)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if application.isPriority {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                    if !application.sourceURL.isEmpty, let url = URL(string: application.sourceURL) {
                        Link(destination: url) {
                            Image(systemName: "link")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .help("Open job posting")
                    }
                }

                HStack(spacing: 6) {
                    if !application.location.isEmpty {
                        Label(application.location, systemImage: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(application.isPriority ? Color.accentColor : .secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 6) {
                    WorkTypeBadge(workType: application.workType)
                    Spacer()
                    if application.hasSalary {
                        Text(application.salaryDisplay)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(application.dateAdded, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        application.isPriority ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.08),
                        lineWidth: application.isPriority ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct WorkTypeBadge: View {
    let workType: WorkType

    var color: Color {
        switch workType {
        case .remote: return .green
        case .hybrid: return .orange
        case .onsite: return .blue
        }
    }

    var body: some View {
        Text(workType.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
