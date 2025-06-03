# SlimDocx 📄✨

A powerful macOS drag-and-drop utility that dramatically reduces DOCX file sizes by removing embedded fonts, compressing images, and eliminating unused assets - all while preserving document quality and formatting.

![SlimDocx Demo](https://img.shields.io/badge/Platform-macOS-blue) ![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## 🚀 Features

### 📉 Massive File Size Reduction
- **Remove embedded fonts** (often 90-99% size reduction)
- **Compress images** using native macOS ImageIO
- **Eliminate unused assets** and orphaned media files
- **Maximum ZIP compression** for final packaging

### 🎯 Smart Font Management
- **Universal font removal** - works with any embedded font format
- **Intelligent font replacement** with system fonts (Calibri, Arial, Times New Roman, etc.)
- **Preserves existing system fonts** - only replaces embedded ones
- **Cleans XML references** and relationship files

### 🖼️ Image Optimization
- **Automatic image compression** (JPEG: 75% quality, PNG: 80% quality)
- **Removes unused media files** by analyzing XML references
- **Supports multiple formats**: JPG, PNG, TIFF, GIF, BMP

### 🔍 Detailed Analysis
- **File structure breakdown** showing what's taking up space
- **Optimization opportunities** identification
- **Before/after size comparison**
- **Comprehensive logging** for troubleshooting

## 📊 Real-World Results

| Document Type | Original Size | Compressed Size | Reduction |
|---------------|---------------|-----------------|-----------|
| Template with Fonts | 6.3 MB | 0.5 MB | **92%** |
| Marketing Brochure | 15.2 MB | 2.1 MB | **86%** |
| Technical Manual | 8.7 MB | 1.2 MB | **86%** |
| Corporate Report | 12.4 MB | 0.8 MB | **94%** |

## 🛠️ Installation

### Via Homebrew (Recommended)
```bash
brew install slim-docx
```

### Manual Download
Download the latest release from [GitHub Releases](https://github.com/vanillalternative/slim-docx/releases)

### Requirements
- macOS 11.0 (Big Sur) or later
- Works on both Intel and Apple Silicon Macs

### Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/vanillalternative/slim-docx.git
   cd SlimDocx
   ```

2. Open in Xcode:
   ```bash
   open SlimDocx.xcodeproj
   ```

3. Build and run (⌘+R)

## 📱 Usage

### Quick Start
1. **Launch SlimDocx**
2. **Drag DOCX files** onto the drop zone
3. **Choose save location** when prompted
4. **Done!** Your compressed file is saved with "- compressed" suffix

📺 **[Watch Video Tutorial](docs/guides/how-to-use.html)** | 📖 **[Complete User Guide](docs/guides/how-to-use.md)**

### What Happens During Compression

```
🔄 Starting compression for: MyDocument.docx
📦 Extracting DOCX (ZIP archive)
🔍 Analyzing file structure...
📊 Total extracted size: 11.9 MB
🏆 Largest files:
   1. 1.3 MB (11.2%) - word/fonts/font11.odttf
   2. 1.3 MB (10.9%) - word/fonts/font12.odttf
   ...
🔤 Removing embedded fonts (11.8 MB)
🖼️ Compressing images
📦 Repackaging with maximum compression
💾 Saving: MyDocument - compressed.docx
✅ Compression completed: 6.3 MB → 0.5 MB (92% reduction)
```

## 🔧 Technical Details

### Architecture
- **Swift 5.0** with native macOS frameworks
- **ImageIO** for image compression
- **NSRegularExpression** for XML processing
- **Process** class for ZIP operations
- **Sandboxed** for security

### Compression Pipeline
1. **Extract** DOCX using built-in `unzip`
2. **Analyze** file structure and identify optimization opportunities
3. **Remove** embedded fonts from `/word/fonts/` directory
4. **Update** XML files to use system fonts
5. **Compress** images using ImageIO with quality settings
6. **Remove** unused assets by analyzing XML references
7. **Repackage** using `zip` with maximum compression (-9)
8. **Save** to user-specified location

### Font Replacement Strategy
```swift
// Replaces any non-system font with rotating system fonts
let systemFonts = ["Calibri", "Arial", "Times New Roman", "Helvetica", "Georgia", "Verdana"]

// Smart detection - preserves existing system fonts
let isSystemFont = systemFonts.contains { systemFont in
    fontName.lowercased().contains(systemFont.lowercased())
}
```

### Security & Permissions
- **App Sandbox** enabled for security
- **User-selected file access** for reading dropped files
- **No network access** - all processing done locally
- **Temporary file cleanup** ensures no data leakage

## 🎯 Use Cases

### 📧 Email Attachments
- Reduce file sizes to meet email attachment limits
- Faster uploads and downloads
- Reduced server storage costs

### 💾 Storage Optimization
- Free up disk space on shared drives
- Reduce backup sizes
- Optimize cloud storage usage

### 🌐 Web Distribution
- Faster website downloads
- Reduced bandwidth costs
- Improved user experience

### 📚 Document Libraries
- Bulk optimization of document collections
- Standardized font usage across organization
- Improved document loading times

## 🔍 Troubleshooting

### Common Issues

**"Failed to compress" error:**
- Check file permissions
- Ensure DOCX file isn't corrupted
- Try a different save location

**No size reduction:**
- File may not contain embedded fonts
- Already optimized document
- Check console logs for details

**Document appearance changed:**
- Font replacement is working correctly
- System fonts provide consistent appearance
- Minor spacing differences are normal

### Debug Mode
Enable detailed logging by running from Xcode:
```
View > Debug Area > Console
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Roadmap
- [ ] **PDF compression** (.pdf files) - Remove embedded fonts and compress images
- [ ] **Video compression** (.mov files) - Reduce video file sizes
- [ ] **File type validation** - Show "not supported" message for invalid files
- [ ] **PowerPoint support** (.pptx files)
- [ ] **Excel support** (.xlsx files)
- [ ] **Batch processing** for multiple files
- [ ] **Custom compression settings** UI
- [ ] **Preview mode** before compression
- [ ] **Undo functionality** 
- [ ] **Command line interface**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple Developer Tools** for excellent macOS development frameworks
- **Microsoft Office Team** for DOCX format specification
- **ZIP specification** maintainers for compression standards
- **Open source community** for inspiration and best practices

## 📞 Support

- **Website**: [vanillalternative.github.io/slim-docx](https://vanillalternative.github.io/slim-docx)
- **User Guide**: [Complete How-To Guide](docs/guides/how-to-use.md)
- **Issues**: [GitHub Issues](https://github.com/vanillalternative/slim-docx/issues)
- **Discussions**: [GitHub Discussions](https://github.com/vanillalternative/slim-docx/discussions)

---

**Made with ❤️ for the macOS community**

*SlimDocx helps you reclaim disk space while maintaining document quality. Perfect for anyone dealing with bloated Office documents!*