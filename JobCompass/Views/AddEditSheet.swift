import SwiftUI
import SwiftData

struct AddEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let application: JobApplication?
    var prefill: JobApplicationPrefill? = nil

    @State private var company = ""
    @State private var role = ""
    @State private var status: ApplicationStatus = .wishlist
    @State private var location = ""
    @State private var workType: WorkType = .remote
    @State private var salaryMinText = ""
    @State private var salaryMaxText = ""
    @State private var notes = ""
    @State private var sourceURL = ""

    private var isEditing: Bool { application != nil }

    private var canSave: Bool {
        !company.trimmingCharacters(in: .whitespaces).isEmpty &&
        !role.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Application" : "New Application")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button(isEditing ? "Save" : "Add") {
                    save()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Core info
                    GroupBox("Position") {
                        Grid(alignment: .leading, verticalSpacing: 10) {
                            GridRow {
                                Text("Company").gridColumnAlignment(.trailing)
                                TextField("e.g. Acme GmbH", text: $company)
                                    .textFieldStyle(.roundedBorder)
                            }
                            GridRow {
                                Text("Role").gridColumnAlignment(.trailing)
                                TextField("e.g. iOS Engineer", text: $role)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Status & logistics
                    GroupBox("Status & Logistics") {
                        Grid(alignment: .leading, verticalSpacing: 10) {
                            GridRow {
                                Text("Status").gridColumnAlignment(.trailing)
                                Picker("", selection: $status) {
                                    ForEach(ApplicationStatus.allCases, id: \.self) { s in
                                        Text(s.rawValue).tag(s)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            GridRow {
                                Text("Location").gridColumnAlignment(.trailing)
                                TextField("City or region", text: $location)
                                    .textFieldStyle(.roundedBorder)
                            }
                            GridRow {
                                Text("Work Type").gridColumnAlignment(.trailing)
                                Picker("", selection: $workType) {
                                    ForEach(WorkType.allCases, id: \.self) { wt in
                                        Text(wt.rawValue).tag(wt)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Salary
                    GroupBox("Salary Range (€)") {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Minimum").font(.caption).foregroundStyle(.secondary)
                                TextField("0", text: $salaryMinText)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Text("–").foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Maximum").font(.caption).foregroundStyle(.secondary)
                                TextField("0", text: $salaryMaxText)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Notes
                    GroupBox("Notes") {
                        TextEditor(text: $notes)
                            .font(.body)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .padding(.top, 4)
                    }

                    // Source URL
                    GroupBox("Job Posting URL") {
                        HStack(spacing: 8) {
                            TextField("https://", text: $sourceURL)
                                .textFieldStyle(.roundedBorder)
                            if let url = URL(string: sourceURL), !sourceURL.isEmpty {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundStyle(Color.accentColor)
                                }
                                .help("Open in browser")
                            }
                        }
                        .padding(.top, 4)
                    }

                    if isEditing, let app = application {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Added \(app.dateAdded.formatted(date: .long, time: .omitted))",
                                  systemImage: "calendar.badge.plus")
                            Label("Updated \(app.lastUpdated.formatted(date: .long, time: .shortened))",
                                  systemImage: "clock.arrow.circlepath")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                        Button(role: .destructive) {
                            if let app = application {
                                modelContext.delete(app)
                            }
                            dismiss()
                        } label: {
                            Label("Delete Application", systemImage: "trash")
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 540)
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        if let app = application {
            company = app.company
            role = app.role
            status = app.status
            location = app.location
            workType = app.workType
            salaryMinText = app.salaryMin > 0 ? "\(app.salaryMin)" : ""
            salaryMaxText = app.salaryMax > 0 ? "\(app.salaryMax)" : ""
            notes = app.notes
            sourceURL = app.sourceURL
        } else if let p = prefill {
            company = p.company ?? ""
            role = p.role ?? ""
            location = p.location ?? ""
            if let wt = p.workType { workType = wt }
            if let min = p.salaryMin { salaryMinText = "\(min)" }
            if let max = p.salaryMax { salaryMaxText = "\(max)" }
            sourceURL = p.sourceURL ?? ""
        }
    }

    private func save() {
        let minSalary = Int(salaryMinText) ?? 0
        let maxSalary = Int(salaryMaxText) ?? 0

        if let app = application {
            app.company = company.trimmingCharacters(in: .whitespaces)
            app.role = role.trimmingCharacters(in: .whitespaces)
            app.status = status
            app.location = location.trimmingCharacters(in: .whitespaces)
            app.workType = workType
            app.salaryMin = minSalary
            app.salaryMax = maxSalary
            app.notes = notes
            app.sourceURL = sourceURL.trimmingCharacters(in: .whitespaces)
            app.lastUpdated = Date()
        } else {
            let newApp = JobApplication(
                company: company.trimmingCharacters(in: .whitespaces),
                role: role.trimmingCharacters(in: .whitespaces),
                status: status,
                location: location.trimmingCharacters(in: .whitespaces),
                workType: workType,
                salaryMin: minSalary,
                salaryMax: maxSalary,
                notes: notes,
                sourceURL: sourceURL.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(newApp)
        }
        dismiss()
    }
}
