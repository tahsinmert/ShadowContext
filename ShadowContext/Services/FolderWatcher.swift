import Foundation

class FolderWatcher {
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private let url: URL
    private let onChange: () -> Void
    
    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
    }
    
    func start() {
        stop()
        
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }
        
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global()
        )
        
        source?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.onChange()
            }
        }
        
        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor {
                close(fd)
            }
            self?.fileDescriptor = -1
        }
        
        source?.resume()
        print("👀 Monitoring changes in: \(url.lastPathComponent)")
    }
    
    func stop() {
        source?.cancel()
        source = nil
    }
    
    deinit {
        stop()
    }
}
