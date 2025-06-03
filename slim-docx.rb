cask "slim-docx" do
  version "1.0.0"
  sha256 "a271012a8f4fdb733155fb0b88c414f71b1b75fd42ee15b90c5ae2c2a0fc8a46"

  url "https://github.com/vanillalternative/slim-docx/releases/download/v#{version}/SlimDocx_Universal_v#{version}.zip"
  name "SlimDocx"
  desc "Compress DOCX files by removing fonts and optimizing images (PDF/MOV support planned)"
  homepage "https://github.com/vanillalternative/slim-docx"

  auto_updates false
  depends_on macos: ">= :big_sur"

  app "SlimDocx.app"

  zap trash: [
    "~/Library/Preferences/com.example.SlimDocx.plist",
    "~/Library/Application Support/SlimDocx",
    "~/Library/Caches/com.example.SlimDocx",
  ]
end