import Foundation

class GitService {
    static let shared = GitService()
    
    func isGitRepository(at url: URL) -> Bool {
        let result = runGit(command: ["rev-parse", "--is-inside-work-tree"], at: url)
        return result.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }
    
    func getCurrentBranch(at url: URL) -> String? {
        let result = runGit(command: ["rev-parse", "--abbrev-ref", "HEAD"], at: url)
        let branch = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return branch.isEmpty ? nil : branch
    }
    
    func getDiff(at url: URL, stagedOnly: Bool = false) -> String {
        var args = ["diff"]
        if stagedOnly { args.append("--staged") }
        return runGit(command: args, at: url)
    }
    
    func getGitMetadata(at url: URL) -> String {
        guard isGitRepository(at: url) else { return "" }
        let branch = getCurrentBranch(at: url) ?? "unknown"
        let remote = runGit(command: ["remote", "get-url", "origin"], at: url).trimmingCharacters(in: .whitespacesAndNewlines)
        
        var meta = "--- GIT CONTEXT ---\n"
        meta += "Branch: \(branch)\n"
        if !remote.isEmpty { meta += "Remote: \(remote)\n" }
        return meta
    }
    
    private func runGit(command: [String], at url: URL) -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = command
        process.currentDirectoryURL = url
        process.standardOutput = pipe
        process.standardError = Pipe() // Ignore errors for now
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
