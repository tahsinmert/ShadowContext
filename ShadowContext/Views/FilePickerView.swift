import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
    var children: [FileItem]?
}

struct FilePickerView: View {
    let rootURL: URL
    @ObservedObject var projectManager = ProjectManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var items: [FileItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Files for Context")
                    .font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    Button("Select All") {
                        let allFiles = getAllFiles(in: items)
                        projectManager.selectAll(files: allFiles)
                    }
                    .buttonStyle(.link)
                    
                    Button("Clear All") {
                        projectManager.deselectAll()
                    }
                    .buttonStyle(.link)
                }
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            List {
                ForEach(items) { item in
                    FileRow(item: item, projectManager: projectManager)
                }
            }
            .listStyle(.sidebar)
            
            HStack {
                Text("\(projectManager.selectedFiles.count) files selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
        }
        .frame(width: 400, height: 500)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .onAppear {
            loadFiles()
        }
    }
    
    private func loadFiles() {
        items = fetchFiles(for: rootURL)
    }
    
    private func fetchFiles(for url: URL) -> [FileItem] {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return [] }
        
        return contents.map { itemURL in
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            var children: [FileItem]? = nil
            if isDir && !["node_modules", ".git", "build", "dist"].contains(itemURL.lastPathComponent) {
                children = fetchFiles(for: itemURL)
            }
            return FileItem(url: itemURL, isDirectory: isDir, children: children)
        }.sorted { $0.url.lastPathComponent < $1.url.lastPathComponent }
    }
    
    private func getAllFiles(in items: [FileItem]) -> [String] {
        var all: [String] = []
        for item in items {
            if !item.isDirectory {
                all.append(item.url.path)
            }
            if let children = item.children {
                all.append(contentsOf: getAllFiles(in: children))
            }
        }
        return all
    }
}

struct FileRow: View {
    let item: FileItem
    @ObservedObject var projectManager: ProjectManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if item.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 12)
                        .onTapGesture { isExpanded.toggle() }
                } else {
                    Spacer().frame(width: 12)
                }
                
                Toggle("", isOn: Binding(
                    get: { projectManager.selectedFiles.contains(item.url.path) },
                    set: { _ in projectManager.toggleFileSelection(path: item.url.path) }
                ))
                .toggleStyle(.checkbox)
                
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(item.isDirectory ? .orange : .secondary)
                
                Text(item.url.lastPathComponent)
                    .font(.system(size: 13))
                
                Spacer()
            }
            
            if isExpanded, let children = item.children {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(children) { child in
                        FileRow(item: child, projectManager: projectManager)
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
}
