import SwiftUI
import SwiftData

struct MenuBarQuickAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    // Pre-fill support for Safari extension handoff
    var prefill: JobApplicationPrefill?

    @State private var company = ""
    @State private var role = ""
    @State private var status: ApplicationStatus = .applied
    @State private var location = ""
    @State private var workType: WorkType = .remote
    @State private var saved = false

    private var canSave: Bool {
        !company.trimmingCharacters(in: .whitespaces).isEmpty &&
        !role.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if saved {
                savedConfirmation
            } else {
                form
            }

            Divider()

            footer
        }
        .frame(width: 320)
        .onAppear { applyPrefill() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "map.fill")
                .foregroundStyle(Color.accentColor)
            Text("Quick Add")
                .font(.headline)
            Spacer()
            Text("JobCompass")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 10) {
            QuickField(label: "Company", placeholder: "e.g. Acme GmbH", text: $company)
            QuickField(label: "Role", placeholder: "e.g. iOS Engineer", text: $role)
            QuickField(label: "Location", placeholder: "City or Remote", text: $location)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Status").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $status) {
                        ForEach(ApplicationStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Work Type").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $workType) {
                        ForEach(WorkType.allCases, id: \.self) { wt in
                            Text(wt.rawValue).tag(wt)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }

            Button(action: save) {
                Text("Save Application")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(14)
    }

    private var savedConfirmation: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("\(company)")
                .font(.headline)
            Text("Added to \(status.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var footer: some View {
        HStack {
            Button("Open JobCompass") {
                openURL(URL(string: "jobcompass://open")!)
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            Spacer()
            if saved {
                Button("Add Another") { reset() }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func save() {
        let app = JobApplication(
            company: company.trimmingCharacters(in: .whitespaces),
            role: role.trimmingCharacters(in: .whitespaces),
            status: status,
            location: location.trimmingCharacters(in: .whitespaces),
            workType: workType
        )
        modelContext.insert(app)
        withAnimation { saved = true }
    }

    private func reset() {
        company = ""; role = ""; location = ""
        status = .applied; workType = .remote
        saved = false
    }

    private func applyPrefill() {
        guard let p = prefill else { return }
        company = p.company ?? ""
        role = p.role ?? ""
        location = p.location ?? ""
        if let wt = p.workType { workType = wt }
    }
}

// Passed in from the Safari extension once it's built
struct JobApplicationPrefill {
    var company: String?
    var role: String?
    var location: String?
    var workType: WorkType?
    var sourceURL: String?
}

private struct QuickField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
