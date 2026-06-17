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

    // Prefill state populated by the Safari extension via URL scheme
    @State private var menuBarPrefill: JobApplicationPrefill? = nil

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    guard url.scheme == "jobcompass" else { return }
                    menuBarPrefill = prefill(from: url)
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        MenuBarExtra("JobCompass", systemImage: "map.fill") {
            MenuBarQuickAddView(prefill: menuBarPrefill)
                .onAppear { menuBarPrefill = nil }
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)
    }

    // Parses jobcompass://quickadd?company=X&role=Y&location=Z&workType=Remote
    private func prefill(from url: URL) -> JobApplicationPrefill? {
        guard url.host == "quickadd",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        let params = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )
        return JobApplicationPrefill(
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
