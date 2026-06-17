import SwiftUI
import SwiftData

// MARK: – Data model for the diagram

struct SankeyNode: Identifiable {
    let id: ApplicationStatus
    let label: String
    let count: Int
    var y: CGFloat = 0
    var height: CGFloat = 0
}

struct SankeyFlow {
    let from: ApplicationStatus
    let to: ApplicationStatus
    let count: Int
}

struct SankeyLayout {
    let nodes: [ApplicationStatus: SankeyNode]
    let flows: [SankeyFlow]
    let columns: [[ApplicationStatus]]
}

// MARK: – View

struct SankeyView: View {
    @Query private var applications: [JobApplication]

    var layout: SankeyLayout {
        buildLayout(from: applications)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Application Flow")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("How applications move through each stage to outcomes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            if applications.isEmpty {
                ContentUnavailableView(
                    "No Applications Yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Add applications on the Kanban board to see your pipeline flow here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Canvas { ctx, size in
                    drawSankey(ctx: ctx, size: size, layout: layout)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: – Layout computation

    private func buildLayout(from apps: [JobApplication]) -> SankeyLayout {
        // Count apps per status
        var counts: [ApplicationStatus: Int] = [:]
        for app in apps {
            counts[app.status, default: 0] += 1
        }

        // Define the stage columns (left to right)
        // Col 0: entry stages   Col 1: interview stages  Col 2: late stages  Col 3: outcomes
        let columns: [[ApplicationStatus]] = [
            [.wishlist, .applied],
            [.hrScreen, .technicalInterview],
            [.finalInterview, .offer],
            [.accepted, .rejected, .withdrawn]
        ]

        // Build flows: each app travels from its current status.
        // We model implied flows: a status implies it passed through all prior stages.
        // Simplified: direct flow to current status from previous column representative.
        var flows: [SankeyFlow] = []

        // Flow edges based on realistic pipeline progression
        let edges: [(ApplicationStatus, ApplicationStatus)] = [
            (.wishlist, .applied),
            (.applied, .hrScreen),
            (.applied, .rejected),
            (.applied, .withdrawn),
            (.hrScreen, .technicalInterview),
            (.hrScreen, .rejected),
            (.hrScreen, .withdrawn),
            (.technicalInterview, .finalInterview),
            (.technicalInterview, .rejected),
            (.technicalInterview, .withdrawn),
            (.finalInterview, .offer),
            (.finalInterview, .rejected),
            (.finalInterview, .withdrawn),
            (.offer, .accepted),
            (.offer, .rejected),
            (.offer, .withdrawn),
        ]

        for (from, to) in edges {
            // Count apps that are at 'to' status, attributing them to this edge.
            // Heuristic: apps in terminal states count on the edge entering that terminal.
            // Apps in pipeline stages are counted on their status column transition.
            let count = counts[to] ?? 0
            if count > 0 {
                flows.append(SankeyFlow(from: from, to: to, count: count))
            }
        }

        // Build node dictionary
        var nodes: [ApplicationStatus: SankeyNode] = [:]
        for status in ApplicationStatus.allCases {
            nodes[status] = SankeyNode(
                id: status,
                label: status.rawValue,
                count: counts[status] ?? 0
            )
        }

        return SankeyLayout(nodes: nodes, flows: flows, columns: columns)
    }

    // MARK: – Drawing

    private func drawSankey(ctx: GraphicsContext, size: CGSize, layout: SankeyLayout) {
        let colCount = layout.columns.count
        let colWidth: CGFloat = size.width / CGFloat(colCount)
        let nodeWidth: CGFloat = 18
        let minNodeHeight: CGFloat = 20
        let nodeGap: CGFloat = 12
        let padding: CGFloat = 40

        // Compute total count (use applied + wishlist as denominator)
        let total = max(1, layout.nodes.values.map(\.count).max() ?? 1)

        // Lay out nodes per column
        var nodeRects: [ApplicationStatus: CGRect] = [:]

        for (colIdx, statuses) in layout.columns.enumerated() {
            let visibleStatuses = statuses.filter { (layout.nodes[$0]?.count ?? 0) > 0 }
            let colCount_nodes = visibleStatuses.count
            let totalHeight = size.height - padding * 2
            let gapTotal = nodeGap * CGFloat(max(0, colCount_nodes - 1))
            let availableHeight = totalHeight - gapTotal

            // Scale node height proportionally
            let colTotal = max(1, visibleStatuses.map { layout.nodes[$0]?.count ?? 0 }.reduce(0, +))
            var yOffset = padding

            let xCenter = colWidth * CGFloat(colIdx) + colWidth / 2

            for status in statuses {
                guard let node = layout.nodes[status], node.count > 0 else { continue }
                let fraction = CGFloat(node.count) / CGFloat(colTotal)
                let height = max(minNodeHeight, fraction * availableHeight)
                nodeRects[status] = CGRect(
                    x: xCenter - nodeWidth / 2,
                    y: yOffset,
                    width: nodeWidth,
                    height: height
                )
                yOffset += height + nodeGap
            }
        }

        // Draw flows (Bézier ribbons)
        for flow in layout.flows {
            guard let fromRect = nodeRects[flow.from],
                  let toRect = nodeRects[flow.to],
                  flow.count > 0 else { continue }

            let fraction = CGFloat(flow.count) / CGFloat(total)
            let ribbonHeight = max(3, fraction * 80)

            let fromX = fromRect.maxX
            let toX = toRect.minX
            let fromY = fromRect.midY
            let toY = toRect.midY

            let cp1 = CGPoint(x: fromX + (toX - fromX) * 0.45, y: fromY)
            let cp2 = CGPoint(x: fromX + (toX - fromX) * 0.55, y: toY)

            var path = Path()
            path.move(to: CGPoint(x: fromX, y: fromY - ribbonHeight / 2))
            path.addCurve(
                to: CGPoint(x: toX, y: toY - ribbonHeight / 2),
                control1: CGPoint(x: cp1.x, y: cp1.y - ribbonHeight / 2),
                control2: CGPoint(x: cp2.x, y: cp2.y - ribbonHeight / 2)
            )
            path.addLine(to: CGPoint(x: toX, y: toY + ribbonHeight / 2))
            path.addCurve(
                to: CGPoint(x: fromX, y: fromY + ribbonHeight / 2),
                control1: CGPoint(x: cp2.x, y: cp2.y + ribbonHeight / 2),
                control2: CGPoint(x: cp1.x, y: cp1.y + ribbonHeight / 2)
            )
            path.closeSubpath()

            let flowColor = nodeColor(for: flow.to).opacity(0.35)
            ctx.fill(path, with: .color(flowColor))
        }

        // Draw nodes
        for (status, rect) in nodeRects {
            let color = nodeColor(for: status)
            let nodePath = Path(roundedRect: rect, cornerRadius: 4)
            ctx.fill(nodePath, with: .color(color))

            guard let node = layout.nodes[status] else { continue }

            // Label to the appropriate side
            let colIdx = layout.columns.firstIndex(where: { $0.contains(status) }) ?? 0
            let isLastCol = colIdx == layout.columns.count - 1

            let label = "\(node.label)\n\(node.count)"
            let textX = isLastCol ? rect.maxX + 6 : rect.minX - 6
            let anchor: Text.TruncationMode = .middle

            ctx.draw(
                Text(node.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.primary),
                at: CGPoint(x: isLastCol ? rect.maxX + 6 : rect.minX - 6, y: rect.midY - 7),
                anchor: isLastCol ? .leading : .trailing
            )
            ctx.draw(
                Text("\(node.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color),
                at: CGPoint(x: isLastCol ? rect.maxX + 6 : rect.minX - 6, y: rect.midY + 7),
                anchor: isLastCol ? .leading : .trailing
            )
            _ = label
            _ = anchor
            _ = textX
        }
    }

    private func nodeColor(for status: ApplicationStatus) -> Color {
        switch status {
        case .wishlist: return .gray
        case .applied: return .blue
        case .hrScreen: return .purple
        case .technicalInterview: return .orange
        case .finalInterview: return Color(hue: 0.14, saturation: 0.8, brightness: 0.85)
        case .offer: return .green
        case .accepted: return .mint
        case .rejected: return .red
        case .withdrawn: return .brown
        }
    }
}
