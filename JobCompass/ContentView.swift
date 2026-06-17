import SwiftUI
import SwiftData

enum AppView: String, CaseIterable, Identifiable {
    case kanban = "Kanban"
    case sankey = "Pipeline Flow"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .kanban: return "rectangle.3.group"
        case .sankey: return "arrow.triangle.branch"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var applications: [JobApplication]

    @State private var selectedView: AppView = .kanban
    @State private var selectedWorkTypes: Set<WorkType> = []
    @State private var locationFilter = ""
    @State private var prefillSheet: JobApplicationPrefill? = nil

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                if selectedView == .kanban {
                    FilterBar(
                        selectedWorkTypes: $selectedWorkTypes,
                        locationFilter: $locationFilter
                    )
                }
                Group {
                    switch selectedView {
                    case .kanban:
                        KanbanView(
                            filterWorkTypes: selectedWorkTypes,
                            filterLocation: locationFilter
                        )
                    case .sankey:
                        SankeyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .sheet(item: $prefillSheet) { prefill in
            AddEditSheet(application: nil, prefill: prefill)
        }
        .onChange(of: appState.pendingPrefill) { _, newPrefill in
            guard let newPrefill else { return }
            prefillSheet = newPrefill
            appState.pendingPrefill = nil
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App branding
            HStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("JobCompass")
                        .font(.headline)
                    Text("\(applications.count) application\(applications.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Navigation items
            List(AppView.allCases, selection: $selectedView) { view in
                Label(view.rawValue, systemImage: view.icon)
                    .tag(view)
            }
            .listStyle(.sidebar)
            .padding(.top, 6)

            Divider()

            // Stats summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Stats")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)

                ForEach(quickStats, id: \.label) { stat in
                    HStack {
                        Circle()
                            .fill(stat.color)
                            .frame(width: 6, height: 6)
                        Text(stat.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(stat.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 240)
    }

    private struct QuickStat {
        let label: String
        let count: Int
        let color: Color
    }

    private var quickStats: [QuickStat] {
        [
            QuickStat(label: "Active", count: applications.filter { $0.status.isPipelineStage }.count, color: .blue),
            QuickStat(label: "Offers", count: applications.filter { $0.status == .offer }.count, color: .green),
            QuickStat(label: "Accepted", count: applications.filter { $0.status == .accepted }.count, color: .mint),
            QuickStat(label: "Rejected", count: applications.filter { $0.status == .rejected }.count, color: .red),
        ]
    }
}
