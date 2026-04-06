import SwiftUI
import WebKit

struct ShadowBotView: View {
    @ObservedObject var botService = BotService.shared
    @State private var inputText: String = ""
    @State private var showWebView: Bool = false
    @State private var githubURL: String = "https://github.com/login"
    
    var projectURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text("ShadowBot Assistant")
                    .font(.headline)
                Spacer()
                Button(action: { showWebView.toggle() }) {
                    Image(systemName: showWebView ? "message.fill" : "globe")
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .help(showWebView ? "Show Chat" : "Open GitHub Web")
            }
            .padding()
            .background(VisualEffectView(material: .menu, blendingMode: .withinWindow))
            
            if showWebView {
                GitHubWebView(url: URL(string: githubURL)!)
                    .transition(.move(edge: .trailing))
            } else {
                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(botService.messages) { msg in
                                HStack {
                                    if msg.isBot {
                                        BotBubble(text: msg.text)
                                        Spacer()
                                    } else {
                                        Spacer()
                                        UserBubble(text: msg.text)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: botService.messages.count) { _ in
                        if let last = botService.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                
                // Input Area
                HStack {
                    TextField("Ask ShadowBot...", text: $inputText, onCommit: sendMessage)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(8)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                }
                .padding()
                .background(VisualEffectView(material: .menu, blendingMode: .withinWindow))
            }
        }
        .frame(width: 350, height: 500)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        botService.processCommand(inputText, for: projectURL)
        inputText = ""
    }
}

struct BotBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(10)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.primary)
            .font(.system(size: 13))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct UserBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(.primary)
            .font(.system(size: 13))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct GitHubWebView: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}
