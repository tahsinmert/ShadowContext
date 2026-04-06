import Foundation

struct Project: Codable, Identifiable, Equatable {
    var id: String { path }
    let path: String
    let name: String
    var lastUsed: Date
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
}

class ProjectManager: ObservableObject {
    static let shared = ProjectManager()
    
    @Published var recentProjects: [Project] = []
    @Published var currentMode: ContextMode = .architecture
    @Published var autoWatchEnabled: Bool = false
    @Published var smartDiffEnabled: Bool = false
    @Published var autoTrimEnabled: Bool = false
    @Published var gitDiffEnabled: Bool = false
    @Published var selectedFiles: Set<String> = []
    
    // Store hashes of files to track changes: [FilePath: ContentHash]
    @Published var lastFileHashes: [String: String] = [:]
    
    private let recentsKey = "ShadowContext_RecentProjects"
    private let settingsKey = "ShadowContext_Settings"
    
    enum ContextMode: String, Codable, CaseIterable {
        case architecture = "Architecture"
        case debugging = "Debugging"
        case feature = "New Feature"
        case refactor = "Refactoring"
        case security = "Security Fix"
        case performance = "Performance"
        case testing = "Testing/QA"
        case documentation = "Documentation"
        case deployment = "Deployment"
        
        var icon: String {
            switch self {
            case .architecture: return "square.stack.3d.up"
            case .debugging: return "ant.fill"
            case .feature: return "plus.square.fill"
            case .refactor: return "hammer.fill"
            case .security: return "shield.fill"
            case .performance: return "bolt.fill"
            case .testing: return "checkmark.seal.fill"
            case .documentation: return "book.fill"
            case .deployment: return "shippingbox.fill"
            }
        }
    }
    
    init() {
        loadRecents()
    }
    
    func toggleFileSelection(path: String) {
        if selectedFiles.contains(path) {
            selectedFiles.remove(path)
        } else {
            selectedFiles.insert(path)
        }
    }
    
    func selectAll(files: [String]) {
        selectedFiles.formUnion(files)
    }
    
    func deselectAll() {
        selectedFiles.removeAll()
    }
    
    func updateFileHash(path: String, content: String) {
        // Simple hash: String length + first/last chars
        let hash = "\(content.count)-\(content.prefix(10))-\(content.suffix(10))"
        lastFileHashes[path] = hash
    }
    
    func hasFileChanged(path: String, content: String) -> Bool {
        let hash = "\(content.count)-\(content.prefix(10))-\(content.suffix(10))"
        return lastFileHashes[path] != hash
    }
    
    func addProject(at url: URL) {
        let newProject = Project(path: url.path, name: url.lastPathComponent, lastUsed: Date())
        
        if let index = recentProjects.firstIndex(where: { $0.path == url.path }) {
            recentProjects.remove(at: index)
        }
        
        recentProjects.insert(newProject, at: 0)
        
        // Keep only top 10
        if recentProjects.count > 10 {
            recentProjects = Array(recentProjects.prefix(10))
        }
        
        saveRecents()
    }
    
    private func saveRecents() {
        if let encoded = try? JSONEncoder().encode(recentProjects) {
            UserDefaults.standard.set(encoded, forKey: recentsKey)
        }
    }
    
    private func loadRecents() {
        if let data = UserDefaults.standard.data(forKey: recentsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            recentProjects = decoded
        }
    }
}
