import SwiftUI

struct FilterBar: View {
    @Binding var selectedWorkTypes: Set<WorkType>
    @Binding var locationFilter: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(.secondary)

            Text("Filter:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Work type toggles
            ForEach(WorkType.allCases, id: \.self) { wt in
                FilterChip(
                    label: wt.rawValue,
                    isSelected: selectedWorkTypes.contains(wt)
                ) {
                    if selectedWorkTypes.contains(wt) {
                        selectedWorkTypes.remove(wt)
                    } else {
                        selectedWorkTypes.insert(wt)
                    }
                }
            }

            Divider().frame(height: 16)

            // Location search
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                TextField("Location", text: $locationFilter)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .frame(width: 120)
                if !locationFilter.isEmpty {
                    Button {
                        locationFilter = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

            if !selectedWorkTypes.isEmpty || !locationFilter.isEmpty {
                Button("Clear") {
                    selectedWorkTypes.removeAll()
                    locationFilter = ""
                }
                .font(.subheadline)
                .foregroundStyle(.red)
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isSelected ? Color.accentColor.opacity(0.15) : Color.clear,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.4),
                            lineWidth: 1
                        )
                )
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}
