import SwiftUI

struct PopoverView: View {
    @ObservedObject var projectManager = ProjectManager.shared
    @State private var selectedFolder: URL?
    @State private var isLastGatherStatus: String = "No context gathered yet"
    @State private var isShowingPreview: Bool = false
    @State private var isShowingFilePicker: Bool = false
    @State private var fullContext: String = ""
    @State private var tokenCount: Int = 0
    @State private var folderWatcher: FolderWatcher?
    @State private var isShowingAdvanced: Bool = false
    @State private var isHovering: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            HeaderView()
            
            // Recent Projects
            if !projectManager.recentProjects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Projects")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(projectManager.recentProjects) { project in
                                Button(action: { selectedFolder = project.url }) {
                                    VStack {
                                        Image(systemName: "folder.fill")
                                            .font(.title2)
                                            .foregroundColor(selectedFolder?.path == project.path ? .orange : .secondary)
                                        Text(project.name)
                                            .font(.system(size: 10))
                                            .lineLimit(1)
                                            .frame(width: 60)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Active Project", systemImage: "folder.fill.badge.gearshape")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedFolder?.path ?? "No Folder Selected")
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        if let folder = selectedFolder, GitService.shared.isGitRepository(at: folder) {
                            HStack(spacing: 4) {
                                Image(systemName: "point.3.connected.trianglepath.dotted")
                                    .font(.system(size: 8))
                                Text(GitService.shared.getCurrentBranch(at: folder) ?? "main")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    
                    if selectedFolder != nil {
                        Button(action: { isShowingFilePicker = true }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                if !projectManager.selectedFiles.isEmpty {
                                    Text("\(projectManager.selectedFiles.count)")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 5, y: -5)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Manage selective context")
                    }
                    
                    Button(action: selectFolder) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Select a project folder")
                }
                
                // Mission Mode Selector (Advanced)
                Menu {
                    ForEach(ProjectManager.ContextMode.allCases, id: \.self) { mode in
                        Button(action: { projectManager.currentMode = mode }) {
                            Label(mode.rawValue, systemImage: mode.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: projectManager.currentMode.icon)
                        Text(projectManager.currentMode.rawValue)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                
                Toggle("Auto-Watch Mode", isOn: $projectManager.autoWatchEnabled)
                    .toggleStyle(.switch)
                    .font(.caption)
                    .tint(.orange)
                    .onChange(of: projectManager.autoWatchEnabled) { enabled in
                        if enabled { startWatching() } else { stopWatching() }
                    }
                
                // Advanced Settings Toggle
                Button(action: { withAnimation { isShowingAdvanced.toggle() } }) {
                    HStack {
                        Text("Advanced Power Tools")
                        Image(systemName: isShowingAdvanced ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                
                if isShowingAdvanced {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Smart Diff Mode", isOn: $projectManager.smartDiffEnabled)
                            .help("Only include files that have changed since last copy.")
                        
                        Toggle("Token Auto-Trim", isOn: $projectManager.autoTrimEnabled)
                            .help("Remove comments and optimize for token efficiency.")
                        
                        Toggle("Git Diff Mode", isOn: $projectManager.gitDiffEnabled)
                            .help("Include current Git changes (Staged & Unstaged) in context.")
                    }
                    .font(.caption)
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Button(action: summonBot) {
                    HStack {
                        Image(systemName: "face.dashed.fill")
                        Text("Summon ShadowBot")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                Button(action: gatherContext) {
                    HStack {
                        Image(systemName: "wand.and.stars.inverse")
                        Text("Gather Context")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(gradient: Gradient(colors: [.orange, .yellow]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(selectedFolder == nil)
                .opacity(selectedFolder == nil ? 0.6 : 1.0)
                
                if !fullContext.isEmpty {
                    HStack {
                        Button(action: { isShowingPreview = true }) {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text("Preview Context")
                            }
                            .foregroundColor(.orange)
                            .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("\(tokenCount) tokens")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                Text(isLastGatherStatus)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            FooterView()
        }
        .padding(.vertical, 20)
        .frame(width: 320)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow).ignoresSafeArea())
        .sheet(isPresented: $isShowingPreview) {
            ContextPreviewView(context: fullContext)
        }
        .sheet(isPresented: $isShowingFilePicker) {
            if let root = selectedFolder {
                FilePickerView(rootURL: root)
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a project folder for AI context"
        
        // Asynchronous approach to prevent main thread freeze
        panel.begin { response in
            if response == .OK {
                if let url = panel.url {
                    DispatchQueue.main.async {
                        self.selectedFolder = url
                        self.projectManager.addProject(at: url)
                        if self.projectManager.autoWatchEnabled {
                            self.startWatching()
                        }
                    }
                }
            }
        }
    }
    
    private func startWatching() {
        guard let url = selectedFolder else { return }
        folderWatcher = FolderWatcher(url: url) {
            print("🔄 Change detected, auto-updating context...")
            gatherContext()
        }
        folderWatcher?.start()
    }
    
    private func stopWatching() {
        folderWatcher?.stop()
        folderWatcher = nil
    }
    
    private func gatherContext() {
        guard let folder = selectedFolder else { return }
        fullContext = ContextEngine.shared.generateContext(
            for: folder,
            mode: projectManager.currentMode,
            selectedFiles: projectManager.selectedFiles,
            smartDiff: projectManager.smartDiffEnabled,
            autoTrim: projectManager.autoTrimEnabled,
            gitDiff: projectManager.gitDiffEnabled
        )
        tokenCount = ContextEngine.shared.estimateTokenCount(for: fullContext)
        PasteboardManager.shared.copyToClipboard(text: fullContext)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        isLastGatherStatus = "Last gathered: \(formatter.string(from: Date()))"
    }
    
    private func summonBot() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.toggleShadowBot(nil)
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .yellow]), startPoint: .top, endPoint: .bottom))
            
            VStack(alignment: .leading) {
                Text("ShadowContext")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("AI Context Gatherer")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct FooterView: View {
    var body: some View {
        HStack {
            Text("⌘ + ⇧ + Space to Trigger")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(4)
            
            Spacer()
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
}

// Visual Effect View for Translucency
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
