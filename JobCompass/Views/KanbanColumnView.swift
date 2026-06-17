import SwiftUI
import SwiftData

struct KanbanColumnView: View {
    let status: ApplicationStatus
    let applications: [JobApplication]
    let onSelect: (JobApplication) -> Void

    var statusColor: Color {
        switch status {
        case .wishlist: return .gray
        case .applied: return .blue
        case .hrScreen: return .purple
        case .technicalInterview: return .orange
        case .finalInterview: return Color(hue: 0.14, saturation: 0.8, brightness: 0.9)
        case .offer: return .green
        case .accepted: return .mint
        case .rejected: return .red
        case .withdrawn: return .brown
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(status.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(applications.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Cards
            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    ForEach(applications) { app in
                        KanbanCardView(application: app) {
                            onSelect(app)
                        }
                    }
                    if applications.isEmpty {
                        Text("No applications")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }
                }
                .padding(10)
            }
        }
        .frame(width: 230)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5)
        )
    }
}
