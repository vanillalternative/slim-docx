import Foundation
import ImageIO
import AppKit

func compressDocxFile(at fileURL: URL) async -> Bool {
    print("🔄 Starting compression for: \(fileURL.lastPathComponent)")
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let extractDir = tempDir.appendingPathComponent("extracted")
    
    print("📁 Temp directory: \(tempDir.path)")
    
    do {
        print("📁 Creating temporary directories...")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
        
        print("📦 Extracting DOCX...")
        guard await extractDocx(from: fileURL, to: extractDir) else {
            print("❌ Failed to extract DOCX")
            return false
        }
        print("✅ DOCX extracted successfully")
        
        // Analyze extracted contents
        analyzeDocxStructure(at: extractDir)
        
        let mediaDir = extractDir.appendingPathComponent("word/media")
        if fileManager.fileExists(atPath: mediaDir.path) {
            print("🖼️ Media directory found, processing assets...")
            if let mediaContents = try? fileManager.contentsOfDirectory(at: mediaDir, includingPropertiesForKeys: nil) {
                print("📋 Media files: \(mediaContents.map { $0.lastPathComponent })")
            }
            removeUnusedAssets(in: extractDir, mediaDir: mediaDir)
            compressImagesInDirectory(mediaDir)
            print("✅ Media processing completed")
        } else {
            print("ℹ️ No media directory found")
        }
        
        // Remove embedded fonts and update font references
        let fontsDir = extractDir.appendingPathComponent("word/fonts")
        if fileManager.fileExists(atPath: fontsDir.path) {
            removeEmbeddedFonts(in: extractDir, fontsDir: fontsDir)
        }
        
        let tempCompressedURL = tempDir.appendingPathComponent("compressed.docx")
        print("📦 Repackaging DOCX...")
        guard await repackageDocx(from: extractDir, to: tempCompressedURL) else {
            print("❌ Failed to repackage DOCX")
            return false
        }
        print("✅ DOCX repackaged successfully")
        
        // Check if compressed file exists and get sizes
        let originalSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        let compressedSize = (try? tempCompressedURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        print("📊 Original size: \(originalSize) bytes, Compressed size: \(compressedSize) bytes")
        
        // Save the file using a save panel on the main thread
        let saveSuccess = await MainActor.run {
            let savePanel = NSSavePanel()
            let originalName = fileURL.deletingPathExtension().lastPathComponent
            savePanel.nameFieldStringValue = "\(originalName) - compressed.docx"
            savePanel.allowedContentTypes = [.init(filenameExtension: "docx")!]
            savePanel.directoryURL = fileURL.deletingLastPathComponent()
            
            if savePanel.runModal() == .OK, let selectedURL = savePanel.url {
                print("💾 Saving compressed file to: \(selectedURL.path)")
                do {
                    if fileManager.fileExists(atPath: selectedURL.path) {
                        try fileManager.removeItem(at: selectedURL)
                        print("🗑️ Removed existing file")
                    }
                    try fileManager.moveItem(at: tempCompressedURL, to: selectedURL)
                    print("✅ Compressed file saved successfully")
                    return true
                } catch {
                    print("❌ Error saving file: \(error)")
                    return false
                }
            } else {
                print("❌ User cancelled save")
                return false
            }
        }
        
        if !saveSuccess {
            return false
        }
        
        try fileManager.removeItem(at: tempDir)
        print("🧹 Temporary files cleaned up")
        print("✅ Compression completed successfully")
        return true
        
    } catch {
        print("❌ Error processing DOCX: \(error)")
        print("🧹 Cleaning up temporary files...")
        try? fileManager.removeItem(at: tempDir)
        return false
    }
}

private func extractDocx(from sourceURL: URL, to destinationURL: URL) async -> Bool {
    print("📦 Running unzip command...")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    process.arguments = ["-q", sourceURL.path, "-d", destinationURL.path]
    
    let pipe = Pipe()
    process.standardError = pipe
    
    print("🔧 Command: /usr/bin/unzip -q \"\(sourceURL.path)\" -d \"\(destinationURL.path)\"")
    
    do {
        try process.run()
        await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }
        
        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        if !errorData.isEmpty, let errorString = String(data: errorData, encoding: .utf8) {
            print("❌ Unzip stderr: \(errorString)")
        }
        
        print("🔧 Unzip exit status: \(process.terminationStatus)")
        return process.terminationStatus == 0
    } catch {
        print("❌ Error running unzip: \(error)")
        return false
    }
}

private func repackageDocx(from sourceDir: URL, to destinationURL: URL) async -> Bool {
    print("📦 Running zip command...")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    process.arguments = ["-r", "-9", "-q", destinationURL.path, "."]
    process.currentDirectoryURL = sourceDir
    
    let pipe = Pipe()
    process.standardError = pipe
    
    print("🔧 Command: cd \"\(sourceDir.path)\" && /usr/bin/zip -r -9 -q \"\(destinationURL.path)\" .")
    
    do {
        try process.run()
        await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }
        
        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        if !errorData.isEmpty, let errorString = String(data: errorData, encoding: .utf8) {
            print("❌ Zip stderr: \(errorString)")
        }
        
        print("🔧 Zip exit status: \(process.terminationStatus)")
        return process.terminationStatus == 0
    } catch {
        print("❌ Error running zip: \(error)")
        return false
    }
}

private func compressImagesInDirectory(_ directory: URL) {
    print("🖼️ Compressing images in directory: \(directory.path)")
    let fileManager = FileManager.default
    
    guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey]) else {
        print("❌ Failed to create enumerator for directory")
        return
    }
    
    var imageCount = 0
    for case let fileURL as URL in enumerator {
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if resourceValues.isRegularFile == true {
                let originalSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                compressImageIfNeeded(at: fileURL)
                let newSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                
                if originalSize != newSize {
                    imageCount += 1
                    print("🖼️ Compressed \(fileURL.lastPathComponent): \(originalSize) → \(newSize) bytes")
                }
            }
        } catch {
            print("❌ Error processing file \(fileURL): \(error)")
        }
    }
    print("✅ Compressed \(imageCount) images")
}

private func compressImageIfNeeded(at fileURL: URL) {
    let fileExtension = fileURL.pathExtension.lowercased()
    
    guard ["jpg", "jpeg", "png", "tiff", "tif"].contains(fileExtension) else {
        print("⏭️ Skipping non-image file: \(fileURL.lastPathComponent)")
        return
    }
    
    print("🖼️ Processing image: \(fileURL.lastPathComponent)")
    
    guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
        print("❌ Failed to create image source for: \(fileURL.lastPathComponent)")
        return
    }
    
    guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("❌ Failed to create image from source: \(fileURL.lastPathComponent)")
        return
    }
    
    let compressionOptions: [CFString: Any]
    let destinationType: CFString
    
    if fileExtension == "png" {
        destinationType = "public.png" as CFString
        compressionOptions = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]
        print("🔧 Compressing PNG with quality 0.8")
    } else {
        destinationType = "public.jpeg" as CFString
        compressionOptions = [
            kCGImageDestinationLossyCompressionQuality: 0.75
        ]
        print("🔧 Compressing JPEG with quality 0.75")
    }
    
    guard let imageDestination = CGImageDestinationCreateWithURL(fileURL as CFURL, destinationType, 1, nil) else {
        print("❌ Failed to create image destination for: \(fileURL.lastPathComponent)")
        return
    }
    
    CGImageDestinationAddImage(imageDestination, image, compressionOptions as CFDictionary)
    let success = CGImageDestinationFinalize(imageDestination)
    
    if success {
        print("✅ Successfully compressed: \(fileURL.lastPathComponent)")
    } else {
        print("❌ Failed to finalize image compression for: \(fileURL.lastPathComponent)")
    }
}

private func removeUnusedAssets(in docxDir: URL, mediaDir: URL) {
    let fileManager = FileManager.default
    
    guard let mediaFiles = try? fileManager.contentsOfDirectory(at: mediaDir, includingPropertiesForKeys: nil) else {
        return
    }
    
    let referencedAssets = findReferencedAssets(in: docxDir)
    
    for mediaFile in mediaFiles {
        let fileName = mediaFile.lastPathComponent
        if !referencedAssets.contains(fileName) {
            print("Removing unused asset: \(fileName)")
            try? fileManager.removeItem(at: mediaFile)
        }
    }
}

private func findReferencedAssets(in docxDir: URL) -> Set<String> {
    var referencedAssets = Set<String>()
    let fileManager = FileManager.default
    
    let xmlPaths = [
        docxDir.appendingPathComponent("word/document.xml"),
        docxDir.appendingPathComponent("word/header1.xml"),
        docxDir.appendingPathComponent("word/header2.xml"),
        docxDir.appendingPathComponent("word/header3.xml"),
        docxDir.appendingPathComponent("word/footer1.xml"),
        docxDir.appendingPathComponent("word/footer2.xml"),
        docxDir.appendingPathComponent("word/footer3.xml"),
        docxDir.appendingPathComponent("word/_rels/document.xml.rels")
    ]
    
    for xmlPath in xmlPaths {
        if fileManager.fileExists(atPath: xmlPath.path) {
            referencedAssets.formUnion(extractAssetReferences(from: xmlPath))
        }
    }
    
    let relsDir = docxDir.appendingPathComponent("word/_rels")
    if fileManager.fileExists(atPath: relsDir.path) {
        if let relFiles = try? fileManager.contentsOfDirectory(at: relsDir, includingPropertiesForKeys: nil) {
            for relFile in relFiles where relFile.pathExtension == "rels" {
                referencedAssets.formUnion(extractAssetReferences(from: relFile))
            }
        }
    }
    
    return referencedAssets
}

private func extractAssetReferences(from xmlFile: URL) -> Set<String> {
    var references = Set<String>()
    
    guard let xmlContent = try? String(contentsOf: xmlFile) else {
        return references
    }
    
    let patterns = [
        #"r:embed="([^"]*image[^"]*)"#,
        #"Target="media/([^"]*)"#,
        #"<pic:cNvPr[^>]*name="([^"]*)"#,
        #"<a:blip[^>]*r:embed="([^"]*)"#,
        #"relationships.*?Target="media/([^"]*)"#
    ]
    
    for pattern in patterns {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let matches = regex.matches(in: xmlContent, range: NSRange(xmlContent.startIndex..., in: xmlContent))
            
            for match in matches {
                if match.numberOfRanges > 1 {
                    let range = match.range(at: 1)
                    if let swiftRange = Range(range, in: xmlContent) {
                        let reference = String(xmlContent[swiftRange])
                        if reference.contains("image") || reference.contains("media") {
                            let fileName = URL(fileURLWithPath: reference).lastPathComponent
                            if !fileName.isEmpty && fileName != "media" {
                                references.insert(fileName)
                            }
                        }
                    }
                }
            }
        } catch {
            print("Regex error for pattern \(pattern): \(error)")
        }
    }
    
    return references
}

private func analyzeDocxStructure(at extractDir: URL) {
    print("🔍 ANALYZING DOCX STRUCTURE")
    print(String(repeating: "=", count: 50))
    
    let fileManager = FileManager.default
    var totalSize: Int64 = 0
    var filesBySize: [(String, Int64)] = []
    
    // Recursively analyze all files
    if let enumerator = fileManager.enumerator(at: extractDir, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]) {
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                if resourceValues.isRegularFile == true {
                    let size = Int64(resourceValues.fileSize ?? 0)
                    totalSize += size
                    
                    let relativePath = String(fileURL.path.dropFirst(extractDir.path.count + 1))
                    filesBySize.append((relativePath, size))
                }
            } catch {
                print("❌ Error analyzing \(fileURL): \(error)")
            }
        }
    }
    
    // Sort by size (largest first)
    filesBySize.sort { $0.1 > $1.1 }
    
    print("📊 Total extracted size: \(formatBytes(totalSize))")
    print("📁 File count: \(filesBySize.count)")
    print("")
    print("🏆 LARGEST FILES:")
    
    for (index, (path, size)) in filesBySize.prefix(15).enumerated() {
        let percentage = Double(size) / Double(totalSize) * 100
        print("\(String(format: "%2d", index + 1)). \(formatBytes(size)) (\(String(format: "%.1f", percentage))%) - \(path)")
    }
    
    print("")
    print("📂 BREAKDOWN BY DIRECTORY:")
    
    var directorySizes: [String: Int64] = [:]
    for (path, size) in filesBySize {
        let components = path.components(separatedBy: "/")
        let directory = components.count > 1 ? components[0] : "root"
        directorySizes[directory, default: 0] += size
    }
    
    let sortedDirs = directorySizes.sorted { $0.value > $1.value }
    for (dir, size) in sortedDirs {
        let percentage = Double(size) / Double(totalSize) * 100
        print("📁 \(formatBytes(size)) (\(String(format: "%.1f", percentage))%) - \(dir)/")
    }
    
    print("")
    print("🎯 OPTIMIZATION OPPORTUNITIES:")
    
    // Check for large XML files that might be optimizable
    let largeXmlFiles = filesBySize.filter { $0.0.hasSuffix(".xml") && $0.1 > 10000 }
    if !largeXmlFiles.isEmpty {
        print("📄 Large XML files found (might contain embedded content):")
        for (path, size) in largeXmlFiles.prefix(5) {
            print("   • \(path): \(formatBytes(size))")
        }
    }
    
    // Check for media files
    let mediaFiles = filesBySize.filter { 
        let ext = ($0.0 as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "wmf", "emf"].contains(ext)
    }
    if !mediaFiles.isEmpty {
        print("🖼️ Media files found:")
        for (path, size) in mediaFiles {
            print("   • \(path): \(formatBytes(size))")
        }
    }
    
    // Check for embedded objects
    let embeddedFiles = filesBySize.filter { $0.0.contains("embeddings") || $0.0.contains("oleObject") }
    if !embeddedFiles.isEmpty {
        print("📎 Embedded objects found:")
        for (path, size) in embeddedFiles {
            print("   • \(path): \(formatBytes(size))")
        }
    }
    
    print(String(repeating: "=", count: 50))
}

private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

private func removeEmbeddedFonts(in docxDir: URL, fontsDir: URL) {
    print("🔤 REMOVING EMBEDDED FONTS")
    let fileManager = FileManager.default
    
    // Get font files before removal for logging
    var fontFiles: [String] = []
    var totalFontSize: Int64 = 0
    
    if let contents = try? fileManager.contentsOfDirectory(at: fontsDir, includingPropertiesForKeys: [.fileSizeKey]) {
        for fontFile in contents {
            fontFiles.append(fontFile.lastPathComponent)
            if let size = try? fontFile.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalFontSize += Int64(size)
            }
        }
    }
    
    print("🗑️ Removing \(fontFiles.count) font files (\(formatBytes(totalFontSize)))")
    
    // Remove the entire fonts directory
    do {
        try fileManager.removeItem(at: fontsDir)
        print("✅ Fonts directory removed")
    } catch {
        print("❌ Error removing fonts directory: \(error)")
        return
    }
    
    // Update font references in XML files to use system fonts
    updateFontReferences(in: docxDir)
    
    print("✅ Font removal completed")
}

private func updateFontReferences(in docxDir: URL) {
    print("🔧 Updating font references to system fonts...")
    
    let xmlFiles = [
        docxDir.appendingPathComponent("word/document.xml"),
        docxDir.appendingPathComponent("word/styles.xml"),
        docxDir.appendingPathComponent("word/numbering.xml"),
        docxDir.appendingPathComponent("word/settings.xml"),
        docxDir.appendingPathComponent("word/fontTable.xml")
    ]
    
    // Standard system fonts to use as replacements
    let systemFonts = ["Calibri", "Arial", "Times New Roman", "Helvetica", "Georgia", "Verdana"]
    
    for xmlFile in xmlFiles {
        guard FileManager.default.fileExists(atPath: xmlFile.path) else { continue }
        
        do {
            var content = try String(contentsOf: xmlFile)
            let originalContent = content
            
            // 1. Remove ALL font embedding references (comprehensive patterns)
            let embeddingPatterns = [
                #"<w:embedRegular[^>]*?/?>"#,
                #"<w:embedBold[^>]*?/?>"#,
                #"<w:embedItalic[^>]*?/?>"#,
                #"<w:embedBoldItalic[^>]*?/?>"#,
                #"w:embedRegular="[^"]*""#,
                #"w:embedBold="[^"]*""#,
                #"w:embedItalic="[^"]*""#,
                #"w:embedBoldItalic="[^"]*""#,
                #"<w:font[^>]*w:embed[^>]*>"#,  // Font elements with embed attributes
                #"w:embed="[^"]*""#             // Any embed attribute
            ]
            
            for pattern in embeddingPatterns {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(content.startIndex..., in: content)
                content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")
            }
            
            // 2. Find and replace ALL non-standard font names with system fonts
            // This covers any custom/embedded font, not just numbered ones
            let fontAttributes = ["w:ascii", "w:hAnsi", "w:eastAsia", "w:cs"]
            var fontReplacementCount = 0
            
            for attribute in fontAttributes {
                // Pattern to match any font that's not already a standard system font
                let pattern = #"\#(attribute)="([^"]*)""#
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
                
                // Process matches in reverse order to avoid index shifting
                for match in matches.reversed() {
                    if match.numberOfRanges > 2 {
                        let fontNameRange = match.range(at: 2)
                        if let range = Range(fontNameRange, in: content) {
                            let fontName = String(content[range])
                            
                            // Skip if it's already a standard system font
                            let isSystemFont = systemFonts.contains { systemFont in
                                fontName.lowercased().contains(systemFont.lowercased())
                            }
                            
                            if !isSystemFont {
                                // Replace with a system font
                                let replacementFont = systemFonts[fontReplacementCount % systemFonts.count]
                                content.replaceSubrange(range, with: replacementFont)
                                fontReplacementCount += 1
                                print("🔄 Replaced font '\(fontName)' with '\(replacementFont)'")
                            }
                        }
                    }
                }
            }
            
            // 3. Remove font table entries for embedded fonts
            if xmlFile.lastPathComponent == "fontTable.xml" {
                // Remove entire font entries that reference embedded fonts
                let fontEntryPattern = #"<w:font[^>]*>.*?</w:font>"#
                let regex = try NSRegularExpression(pattern: fontEntryPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
                
                // Check each font entry for embedding references
                for match in matches.reversed() {
                    if let range = Range(match.range, in: content) {
                        let fontEntry = String(content[range])
                        if fontEntry.contains("embed") || fontEntry.contains("font\\d+") {
                            content.removeSubrange(range)
                            print("🗑️ Removed embedded font entry from font table")
                        }
                    }
                }
            }
            
            // 4. Clean up any orphaned font references
            let cleanupPatterns = [
                #"<w:font\s+w:name="[^"]*font\d+[^"]*"[^>]*>.*?</w:font>"#,  // Numbered font entries
                #"w:name="[^"]*font\d+[^"]*""#,                               // Numbered font names
                #"<w:font[^>]*>\s*</w:font>"#                                 // Empty font elements
            ]
            
            for pattern in cleanupPatterns {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let range = NSRange(content.startIndex..., in: content)
                content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")
            }
            
            if content != originalContent {
                try content.write(to: xmlFile, atomically: true, encoding: .utf8)
                print("✅ Updated font references in \(xmlFile.lastPathComponent)")
            }
            
        } catch {
            print("❌ Error processing \(xmlFile.lastPathComponent): \(error)")
        }
    }
    
    // 5. Clean up relationship files - remove ALL font-related relationships
    let relationshipFiles = [
        docxDir.appendingPathComponent("word/_rels/document.xml.rels"),
        docxDir.appendingPathComponent("_rels/.rels")
    ]
    
    for relsFile in relationshipFiles {
        guard FileManager.default.fileExists(atPath: relsFile.path) else { continue }
        
        do {
            var content = try String(contentsOf: relsFile)
            let originalContent = content
            
            // Remove any relationship that points to fonts
            let fontRelPatterns = [
                #"<Relationship[^>]*Type="[^"]*font[^"]*"[^>]*/?>"#,      // Font type relationships
                #"<Relationship[^>]*Target="[^"]*font[^"]*"[^>]*/?>"#,    // Font target relationships
                #"<Relationship[^>]*Target="fonts/[^"]*"[^>]*/?>"#        // Fonts directory relationships
            ]
            
            for pattern in fontRelPatterns {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(content.startIndex..., in: content)
                content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")
            }
            
            if content != originalContent {
                try content.write(to: relsFile, atomically: true, encoding: .utf8)
                print("✅ Updated font relationships in \(relsFile.lastPathComponent)")
            }
            
        } catch {
            print("❌ Error updating font relationships in \(relsFile.lastPathComponent): \(error)")
        }
    }
    
    print("✅ Comprehensive font cleanup completed")
}