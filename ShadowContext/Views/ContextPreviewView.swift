import SwiftUI

struct ContextPreviewView: View {
    let context: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Context Preview")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(context)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color.white.opacity(0.05))
            
            // Footer
            HStack {
                Button(action: {
                    PasteboardManager.shared.copyToClipboard(text: context)
                }) {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc.fill")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
        }
        .frame(width: 450, height: 550)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}
