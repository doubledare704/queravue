import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var endToEndActivity: NSObjectProtocol?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    if ProcessInfo.processInfo.environment["QUERAVUE_E2E"] == "1" {
      keepVisibleForEndToEndTests()
    }
  }

  // A hidden or covered window draws no frames, and every test pump waits for one (docs/testing.md).
  private func keepVisibleForEndToEndTests() {
    endToEndActivity = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiated, .idleDisplaySleepDisabled],
      reason: "End-to-end tests need the window to keep drawing")
    level = .floating
    // A full-screen app elsewhere sits on its own Space; join it so the window stays on screen.
    collectionBehavior.formUnion([.canJoinAllSpaces, .fullScreenAuxiliary])
    NotificationCenter.default.addObserver(
      forName: NSApplication.didHideNotification, object: nil, queue: .main
    ) { [weak self] _ in
      // Unhiding inside the notification is ignored while the hide completes.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self?.bringToFront() }
    }
    DispatchQueue.main.async { [weak self] in self?.bringToFront() }
  }

  private func bringToFront() {
    NSApp.unhide(nil)
    NSApp.activate(ignoringOtherApps: true)
    makeKeyAndOrderFront(nil)
  }
}
