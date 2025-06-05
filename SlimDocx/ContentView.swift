import SwiftUI
import ImageIO
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var statusMessage = "Drop DOCX files here to compress them"
    @State private var isProcessing = false
    @State private var isDragOver = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Drop zone
            DropZoneView(
                isDragOver: $isDragOver,
                onDrop: processDocxFiles
            )
            .frame(width: 400, height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isDragOver ? Color.accentColor : Color.secondary, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            
            // Status area
            VStack(spacing: 10) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Text(statusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(30)
        .frame(width: 500, height: 350)
    }
    
    private func processDocxFiles(_ urls: [URL]) {
        let docxFiles = urls.filter { $0.pathExtension.lowercased() == "docx" }
        
        guard !docxFiles.isEmpty else {
            updateStatus("❌ Please drop only DOCX files")
            return
        }
        
        isProcessing = true
        
        for docxFile in docxFiles {
            processDocxFile(at: docxFile)
        }
    }
    
    private func updateStatus(_ message: String, resetAfter duration: TimeInterval = 0) {
        statusMessage = message
        
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                statusMessage = "Drop DOCX files here to compress them"
            }
        }
    }
    
    private func processDocxFile(at url: URL) {
        updateStatus("Processing \(url.lastPathComponent)...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = compressDocxFile(at: url)
            
            DispatchQueue.main.async {
                isProcessing = false
                
                if success {
                    let originalName = url.deletingPathExtension().lastPathComponent
                    updateStatus("✅ Created \(originalName) - compressed.docx", resetAfter: 4)
                } else {
                    updateStatus("❌ Failed to compress \(url.lastPathComponent)", resetAfter: 4)
                }
            }
        }
    }
}

struct DropZoneView: View {
    @Binding var isDragOver: Bool
    let onDrop: ([URL]) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Drop DOCX files here")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let dispatchGroup = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            dispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { dispatchGroup.leave() }
                
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            onDrop(urls)
        }
        
        return true
    }
}

#Preview {
    ContentView()
}