import Foundation

class BotService: ObservableObject {
    static let shared = BotService()
    
    @Published var messages: [BotMessage] = [
        BotMessage(text: "Hello! I am ShadowBot. How can I help with your Git tasks today?", isBot: true)
    ]
    
    struct BotMessage: Identifiable {
        let id = UUID()
        let text: String
        let isBot: Bool
        let timestamp = Date()
    }
    
    func processCommand(_ command: String, for url: URL?) {
        guard let url = url else {
            addMessage("Please select a project folder first.", isBot: true)
            return
        }
        
        addMessage(command, isBot: false)
        let lowerCommand = command.lowercased()
        
        if lowerCommand.contains("pull") {
            executeGitAction(args: ["pull"], successMsg: "Successfully pulled latest changes.", at: url)
        } else if lowerCommand.contains("push") {
            executeGitAction(args: ["push"], successMsg: "Successfully pushed your changes to remote.", at: url)
        } else if lowerCommand.contains("status") {
            let status = GitService.shared.getGitMetadata(at: url)
            addMessage("Current Status:\n\(status)", isBot: true)
        } else if lowerCommand.contains("diff") {
            let diff = GitService.shared.getDiff(at: url)
            addMessage(diff.isEmpty ? "No changes to show." : "Here is the current diff:\n\(diff.prefix(500))...", isBot: true)
        } else {
            addMessage("I'm still learning! Try 'pull', 'push', 'status', or 'diff'.", isBot: true)
        }
    }
    
    private func executeGitAction(args: [String], successMsg: String, at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = url
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                addMessage(successMsg, isBot: true)
            } else {
                addMessage("Git command failed with status \(process.terminationStatus).", isBot: true)
            }
        } catch {
            addMessage("Failed to execute command: \(error.localizedDescription)", isBot: true)
        }
    }
    
    private func addMessage(_ text: String, isBot: Bool) {
        DispatchQueue.main.async {
            self.messages.append(BotMessage(text: text, isBot: isBot))
        }
    }
}
