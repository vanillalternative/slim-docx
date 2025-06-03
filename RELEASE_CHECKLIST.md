# Release Checklist

## GitHub Release Steps

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Initial release v1.0.0"
   git tag v1.0.0
   git push origin main
   git push origin v1.0.0
   ```

2. **Create GitHub Release:**
   - Go to: https://github.com/vanillalternative/slim-docx/releases/new
   - Tag: `v1.0.0`
   - Title: `SlimDocx v1.0.0`
   - Description: Copy from release notes below
   - Upload: `dist/SlimDocx_Universal_v1.0.zip`

3. **Get SHA256 hash:**
   ```bash
   shasum -a 256 dist/SlimDocx_Universal_v1.0.zip
   ```

4. **Update Homebrew formula:**
   - Replace `REPLACE_WITH_ACTUAL_SHA256` in `slim-docx.rb`
   - Replace `vanillalternative` with your GitHub username (already done)

## Homebrew Submission Steps

1. **Fork homebrew-cask:**
   - Go to: https://github.com/Homebrew/homebrew-cask
   - Click "Fork"

2. **Add your cask:**
   ```bash
   git clone https://github.com/vanillalternative/homebrew-cask.git
   cd homebrew-cask
   cp ../slim-docx/slim-docx.rb Casks/
   git add Casks/slim-docx.rb
   git commit -m "Add slim-docx cask"
   git push origin main
   ```

3. **Create Pull Request:**
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Title: `Add slim-docx cask`

## Release Notes Template

```markdown
# SlimDocx v1.0.0

A macOS drag-and-drop utility that dramatically reduces DOCX file sizes by removing embedded fonts and compressing images.

## ✨ Features
- **Massive size reduction** (up to 99% smaller files)
- **Remove embedded fonts** and replace with system fonts
- **Compress images** using native macOS frameworks
- **Universal binary** for Intel and Apple Silicon Macs
- **Simple drag-and-drop** interface

## 📥 Installation

### Homebrew (Recommended)
```bash
brew install slim-docx
```

### Manual Download
Download and extract `SlimDocx_Universal_v1.0.zip`, then drag to Applications folder.

## 📊 Typical Results
- Marketing documents: 86-94% size reduction
- Templates with fonts: 90-99% size reduction
- Reports with images: 80-90% size reduction

## 🔧 System Requirements
- macOS 11.0 (Big Sur) or later
- Works on both Intel and Apple Silicon Macs

## 🐛 Known Issues
- First launch may require security approval (normal for unsigned apps)
- Minor font spacing differences due to system font replacement

See full documentation at: https://github.com/vanillalternative/slim-docx
```

## After Release

1. **Test Homebrew installation:**
   ```bash
   brew install slim-docx
   ```

2. **Update README with real GitHub URLs**

3. **Announce on:**
   - Reddit r/MacApps
   - Hacker News
   - Product Hunt
   - Twitter/X