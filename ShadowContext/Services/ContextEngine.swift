import Foundation

class ContextEngine {
    static let shared = ContextEngine()
    
    private var ignorePatterns: [String] = [".git", "node_modules", "build", "dist", ".DS_Store"]

    func generateContext(
        for url: URL,
        mode: ProjectManager.ContextMode = .architecture,
        selectedFiles: Set<String> = [],
        smartDiff: Bool = false,
        autoTrim: Bool = false,
        gitDiff: Bool = false
    ) -> String {
        loadIgnorePatterns(from: url)
        
        let framework = detectFramework(at: url)
        let tree = generateTree(at: url, depth: 3)
        
        var context = "Project: \(url.lastPathComponent)\n"
        context += "Framework: \(framework)\n"
        
        // Git Metadata
        if GitService.shared.isGitRepository(at: url) {
            context += GitService.shared.getGitMetadata(at: url)
            
            if gitDiff {
                let staged = GitService.shared.getDiff(at: url, stagedOnly: true)
                let unstaged = GitService.shared.getDiff(at: url, stagedOnly: false)
                
                if !staged.isEmpty {
                    context += "\n--- GIT DIFF (STAGED) ---\n```diff\n\(staged.prefix(5000))\n```\n"
                }
                if !unstaged.isEmpty {
                    context += "\n--- GIT DIFF (UNSTAGED) ---\n```diff\n\(unstaged.prefix(5000))\n```\n"
                }
            }
        }
        
        context += "\n--- MISSION MODE: \(mode.rawValue) ---\n"
        
        context += """
        
        ## Mission Instructions:
        \(getMissionInstructions(for: mode))
        
        ## Directory Structure:
        \(tree)
        
        ## System Summary:
        This is a \(framework) project. Please use this context for all code generation and analysis.
        """
        
        // Add content of key files if they are selected
        // We use a broader approach: if selectedFiles is empty, we can choose to include nothing or a default set.
        // For this Pro feature, we only include what is explicitly selected.
        for filePath in selectedFiles {
            let fileURL = URL(fileURLWithPath: filePath)
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                
                // Smart Diff Logic
                if smartDiff && !ProjectManager.shared.hasFileChanged(path: filePath, content: content) {
                    continue
                }
                
                var processedContent = content
                
                // Auto-Trim Logic (Simple Optimization)
                if autoTrim {
                    processedContent = optimizeContent(content)
                }
                
                context += "\n\n### Content of \(fileURL.lastPathComponent):\n"
                if smartDiff { context += "*(Changed)*\n" }
                context += "```\n\(processedContent.prefix(2000))\n```"
                
                // Update tracking hash
                ProjectManager.shared.updateFileHash(path: filePath, content: content)
            }
        }
        
        return context
    }
    
    private func getMissionInstructions(for mode: ProjectManager.ContextMode) -> String {
        switch mode {
        case .architecture:
            return """
            MISSION: High-Level System Analysis.
            - Focus on the overall architecture, design patterns (MVVM, Singleton, etc.), and data flow.
            - Identify key dependencies and architectural bottlenecks.
            - Explain how components interact at a structural level.
            """
        case .debugging:
            return """
            MISSION: Deep Logic & Edge Case Discovery.
            - Analyze the logic for potential race conditions, null pointers, or unhandled states.
            - Focus on error handling blocks and 'guard' statements.
            - Propose specific fixes for logical inconsistencies.
            """
        case .feature:
            return """
            MISSION: New Functionality Integration.
            - Identify the best extension points for new features.
            - Ensure UI/Logic consistency with the existing codebase.
            - Suggest where to add new files or modify existing ones to maintain clean code.
            """
        case .refactor:
            return """
            MISSION: Technical Debt & Style Optimization.
            - Identify code smells, duplicated logic, and violate DRY principles.
            - Suggest modern Swift APIs or cleaner SwiftUI patterns to simplify the code.
            - Focus on improving readability and maintainability.
            """
        case .security:
            return """
            MISSION: Vulnerability & Best Practice Audit.
            - Scan for hardcoded secrets, unsafe API usage, or insecure data storage.
            - Focus on network security, authentication flows, and sandbox permissions.
            - Propose mitigations based on OWASP and Apple Security guidelines.
            """
        case .performance:
            return """
            MISSION: Resource & Speed Optimization.
            - Identify heavy computations on the main thread and potential memory leaks.
            - Analyze list/scroll performance and redraw cycles in SwiftUI.
            - Suggest lazy loading, caching strategies, or background processing improvements.
            """
        case .testing:
            return """
            MISSION: QA & Test Coverage Planning.
            - Identify critical paths that require Unit or UI tests.
            - Propose XCTest test cases and mock data structures for dependency injection.
            - Suggest ways to make the code more testable (mockable).
            """
        case .documentation:
            return """
            MISSION: Technical Writing & Clarity.
            - Generate comprehensive README sections or DocC comments for public APIs.
            - Focus on explaining 'why' certain architectural decisions were made.
            - Simplify complex logic into human-readable technical documentation.
            """
        case .deployment:
            return """
            MISSION: DevOps & Production Readiness.
            - Review Info.plist, build settings, and entitlement configurations.
            - Analyze CI/CD potential and environment variable management.
            - Focus on App Store guidelines and production environment stability.
            """
        }
    }
    
    private func optimizeContent(_ content: String) -> String {
        // Basic comment removal (JS/Swift style //)
        let lines = content.components(separatedBy: .newlines)
        let optimized = lines.map { line -> String in
            if let range = line.range(of: "//") {
                return String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            return line
        }.filter { !$0.isEmpty }
        
        return optimized.joined(separator: "\n")
    }
    
    func estimateTokenCount(for text: String) -> Int {
        // Very rough heuristic: Word count * 1.3 (approx tokens for English/Code)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return Int(Double(words.count) * 1.4)
    }
    
    private func loadIgnorePatterns(from url: URL) {
        let gitignoreURL = url.appendingPathComponent(".gitignore")
        if let content = try? String(contentsOf: gitignoreURL, encoding: .utf8) {
            let lines = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            ignorePatterns.append(contentsOf: lines)
        }
    }
    
    private func detectFramework(at url: URL) -> String {
        let fileManager = FileManager.default
        let contents = (try? fileManager.contentsOfDirectory(atPath: url.path)) ?? []
        
        if contents.contains("package.json") { return "Node.js/Web" }
        if contents.contains("Package.swift") { return "Swift/iOS/macOS" }
        if contents.contains("pubspec.yaml") { return "Flutter" }
        if contents.contains("requirements.txt") || contents.contains("pyproject.toml") { return "Python" }
        if contents.contains("Cargo.toml") { return "Rust" }
        if contents.contains("go.mod") { return "Go" }
        
        return "Generic/Unknown"
    }
    
    private func generateTree(at url: URL, depth: Int, currentDepth: Int = 0) -> String {
        guard currentDepth < depth else { return "" }
        
        let fileManager = FileManager.default
        let contents = (try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        
        var tree = ""
        let sortedContents = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
        
        for item in sortedContents {
            let indent = String(repeating: "  ", count: currentDepth)
            let name = item.lastPathComponent
            let isDirectory = (try? item.resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory) ?? false
            
            // Respect ignore patterns
            if ignorePatterns.contains(where: { name.contains($0) || $0 == name }) {
                continue
            }
            
            tree += "\(indent) \(isDirectory ? "📁" : "📄") \(name)\n"
            
            if isDirectory && currentDepth < depth - 1 {
                tree += generateTree(at: item, depth: depth, currentDepth: currentDepth + 1)
            }
        }
        return tree
    }
}
