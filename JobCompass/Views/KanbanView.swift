import SwiftUI
import SwiftData

struct KanbanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JobApplication.dateAdded) private var allApplications: [JobApplication]

    let filterWorkTypes: Set<WorkType>
    let filterLocation: String

    @State private var selectedApp: JobApplication?
    @State private var showingAddSheet = false

    var filteredApplications: [JobApplication] {
        allApplications.filter { app in
            let workTypeMatch = filterWorkTypes.isEmpty || filterWorkTypes.contains(app.workType)
            let locationMatch = filterLocation.isEmpty ||
                app.location.localizedCaseInsensitiveContains(filterLocation)
            return workTypeMatch && locationMatch
        }
    }

    func apps(for status: ApplicationStatus) -> [JobApplication] {
        filteredApplications.filter { $0.status == status }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(ApplicationStatus.allCases, id: \.self) { status in
                    KanbanColumnView(
                        status: status,
                        applications: apps(for: status),
                        onSelect: { app in selectedApp = app }
                    )
                }
            }
            .padding(16)
        }
        .background(.background)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Application", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditSheet(application: nil)
        }
        .sheet(item: $selectedApp) { app in
            AddEditSheet(application: app)
        }
    }
}
