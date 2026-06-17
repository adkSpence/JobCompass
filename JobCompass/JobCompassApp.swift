import SwiftUI
import SwiftData

@main
struct JobCompassApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([JobApplication.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    guard url.scheme == "jobcompass",
                          url.host == "quickadd",
                          let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    else { return }

                    let params = Dictionary(
                        uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                            item.value.map { (item.name, $0) }
                        }
                    )

                    appState.pendingPrefill = JobApplicationPrefill(
                        company: params["company"],
                        role: params["role"],
                        location: params["location"],
                        workType: params["workType"].flatMap { WorkType(rawValue: $0) },
                        salaryMin: params["salaryMin"].flatMap { Int($0) },
                        salaryMax: params["salaryMax"].flatMap { Int($0) },
                        sourceURL: params["url"]
                    )
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        MenuBarExtra("JobCompass", systemImage: "map.fill") {
            MenuBarQuickAddView()
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)
    }
}
