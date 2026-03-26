import SwiftUI

struct TerminalSessionRow: View {
    let session: TerminalSession
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("terminalClickAction") private var terminalClickAction = "panel"

    private var tag: String {
        RepositoryViewModel.terminalTagPrefix + session.id.uuidString
    }

    var body: some View {
        HStack(spacing: 6) {
            programIcon
                .frame(width: 16, height: 16)

            Text(session.title)
                .lineLimit(1)

            Spacer()

            activityIndicator
        }
        .background { if session.activityState == .busy { ShineEffect(color: session.program.color).padding(.vertical, -8).padding(.horizontal, -12) } }
        .tag(tag)
        .contextMenu {
            Button {
                openFullScreen()
            } label: {
                Label("Open Full Screen", systemImage: "macwindow")
            }
            Button {
                viewModel.showInPanel(session)
            } label: {
                Label("Show in Panel", systemImage: "rectangle.split.1x2")
            }
            Divider()
            Button(role: .destructive) {
                viewModel.closeTerminal(session)
            } label: {
                Label("Close Terminal", systemImage: "xmark.circle")
            }
        }
    }

    @ViewBuilder
    private var programIcon: some View {
        if session.program.isCustomImage {
            Image(session.program.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(session.isRunning ? session.program.color : .secondary)
        } else {
            Image(systemName: session.program.icon)
                .foregroundStyle(session.isRunning ? session.program.color : .secondary)
        }
    }

    @ViewBuilder
    private var activityIndicator: some View {
        switch session.activityState {
        case .loading:
            HStack(spacing: 3) {
                BouncingDots(color: session.program.color)
            }
        case .busy:
            HStack(spacing: 3) {
                BouncingDots(color: session.program.color)
            }
        case .idle:
            EmptyView()
        }
    }

    private func openFullScreen() {
        viewModel.selectedFilePaths = [tag]
        viewModel.selectedFilePath = tag
    }
}

// MARK: - Bouncing dots indicator

private struct BouncingDots: View {
    let color: Color
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(color)
                    .frame(width: 3.5, height: 3.5)
                    .offset(y: animating ? -2 : 2)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Shine sweep effect

private struct ShineEffect: View {
    let color: Color
    @State private var phase: CGFloat = -0.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: color.opacity(0.18), location: 0.4),
                            .init(color: color.opacity(0.25), location: 0.5),
                            .init(color: color.opacity(0.18), location: 0.6),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: w * 0.7, height: h)
                .offset(x: w * phase)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                        phase = 1.2
                    }
                }
        }
        .allowsHitTesting(false)
        .clipShape(.rect(cornerRadius: 6))
    }
}
