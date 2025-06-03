# How to Use SlimDocx

A step-by-step guide to compressing your DOCX files with SlimDocx.

## 📹 Video Tutorial

Watch the complete tutorial showing how to use SlimDocx:

https://github.com/vanillalternative/slim-docx/raw/main/docs/assets/docx.mov

## 🚀 Quick Start

### 1. Launch SlimDocx
- Double-click the SlimDocx app in your Applications folder
- The main window will open with a drag-and-drop zone

### 2. Select Your DOCX File
Simply drag and drop your DOCX file onto the drop zone, or:
- Click the drop zone to open a file picker
- Navigate to your DOCX file and select it

### 3. Choose Save Location
- A save dialog will appear
- Choose where you want to save the compressed file
- The app will automatically add "- compressed" to the filename

### 4. Watch the Magic Happen
SlimDocx will:
- Extract the DOCX contents
- Analyze the file structure
- Remove embedded fonts
- Compress images
- Repackage everything with maximum compression

### 5. View Results
- A completion message shows the size reduction
- Your compressed file is saved to the chosen location
- Original file remains unchanged

## 📊 What to Expect

### Typical Compression Results:
- **Documents with embedded fonts**: 90-99% size reduction
- **Image-heavy documents**: 70-85% size reduction
- **Simple text documents**: 20-40% size reduction

### Processing Time:
- **Small files (< 1MB)**: Instant
- **Medium files (1-10MB)**: 2-5 seconds
- **Large files (10MB+)**: 5-15 seconds

## 🔍 Understanding the Output

During compression, you'll see detailed logging:

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

## 🎯 Pro Tips

### Best Results:
1. **Template files** with custom fonts see the biggest reductions
2. **Marketing materials** often have large embedded fonts
3. **Corporate documents** frequently contain unnecessary font files

### Before Compressing:
- Make a backup copy of important documents
- Test compressed files to ensure they look correct
- Remember that font changes are permanent

### After Compressing:
- Fonts will be replaced with system fonts (Calibri, Arial, etc.)
- Document layout should remain the same
- File compatibility with all Office versions is maintained

## 🛠️ Troubleshooting

### Common Issues:

**"Failed to compress" error:**
- Check that the file isn't corrupted
- Ensure you have write permissions to the save location
- Try saving to a different location

**Document looks different:**
- This is normal - embedded fonts are replaced with system fonts
- Layout and formatting are preserved
- Text content remains unchanged

**No size reduction:**
- File may not contain embedded fonts
- Document might already be optimized
- Check the console output for details

**App won't launch:**
- First launch requires security approval
- Right-click → "Open" instead of double-clicking
- Go to Security & Privacy settings to allow the app

### Getting Help:
- Check the [GitHub Issues](https://github.com/vanillalternative/slim-docx/issues)
- View console logs for detailed error messages
- Report bugs with sample files (remove sensitive content)

## 🔄 Batch Processing

Currently, SlimDocx processes one file at a time. For multiple files:

1. Process each file individually
2. Use a consistent naming convention
3. Save all compressed files to the same folder
4. Batch processing is planned for future versions

## 📝 File Compatibility

### Supported:
- **.docx** files (Microsoft Word 2007+)
- Files created in Word, Google Docs, LibreOffice, etc.
- Password-protected files (will prompt for password)

### Not Supported Yet:
- **.doc** files (legacy Word format)
- **.pdf** files (planned for future release)
- **.pptx** or **.xlsx** files (on roadmap)

## 🎨 Understanding Font Replacement

SlimDocx replaces embedded fonts with these system fonts:
- **Calibri** (primary replacement)
- **Arial** (secondary)
- **Times New Roman** (for serif fonts)
- **Helvetica** (for sans-serif)
- **Georgia** (for serif headings)
- **Verdana** (for small text)

This ensures:
- Documents open on any Mac without missing fonts
- Consistent appearance across systems
- Significant file size reduction

---

**Need more help?** Check out our [FAQ](https://github.com/vanillalternative/slim-docx/wiki) or [open an issue](https://github.com/vanillalternative/slim-docx/issues/new).