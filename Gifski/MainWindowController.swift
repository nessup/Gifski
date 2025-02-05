import Cocoa
import AVFoundation
import Crashlytics
import DockProgress

final class MainWindowController: NSWindowController {
	private let videoValidator = VideoValidator()

	var isConverting: Bool {
		window?.contentViewController is ConversionViewController
	}

	private func showWelcomeScreen() {
		guard App.isFirstLaunch else {
			return
		}

		NSAlert.showModal(
			for: window,
			message: "Welcome to Gifski!",
			informativeText:
				"""
				Keep in mind that the GIF image format is very space inefficient. Only convert short video clips unless you want huge files.

				If you have any feedback, bug reports, or feature requests, kindly use the “Send Feedback” button in the “Help” menu. We respond to all submissions and reported issues will be dealt with swiftly. It's preferable that you report bugs this way rather than as an App Store review, since the App Store will not allow us to contact you for more information.
				"""
		)
	}

	convenience init() {
		let window = NSWindow.centeredWindow(size: .zero)
		window.contentViewController = VideoDropViewController()
		window.centerNatural()
		self.init(window: window)

		with(window) {
			$0.delegate = self
			$0.titleVisibility = .hidden
			$0.styleMask = [
				.titled,
				.closable,
				.miniaturizable,
				.fullSizeContentView
			]
			$0.tabbingMode = .disallowed
			$0.collectionBehavior = .fullScreenNone
			$0.titlebarAppearsTransparent = true
			$0.isMovableByWindowBackground = true
			$0.isRestorable = false
			$0.makeVibrant()
		}

		NSApp.activate(ignoringOtherApps: false)
		window.makeKeyAndOrderFront(nil)

		DockProgress.style = .circle(radius: 55)

		showWelcomeScreen()
	}

	func presentOpenPanel() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories = false
		panel.canCreateDirectories = false
		panel.allowedFileTypes = System.supportedVideoTypes

		panel.beginSheetModal(for: window!) { [weak self] in
			guard $0 == .OK else {
				return
			}

			// Give the system time to close the sheet.
			DispatchQueue.main.async {
				self?.convert(panel.url!)
			}
		}
	}

	@objc
	func open(_ sender: AnyObject) {
		presentOpenPanel()
	}

	func convert(_ inputUrl: URL) {
		guard
			!isConverting,
			case let .success(asset, videoMetadata) = videoValidator.validate(inputUrl, in: window)
		else {
			return
		}

		let editController = EditVideoViewController(inputUrl: inputUrl, asset: asset, videoMetadata: videoMetadata)
		window?.contentViewController?.push(viewController: editController)
	}
}

extension MainWindowController: NSMenuItemValidation {
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.action {
		case #selector(open)?:
			return !isConverting
		default:
			return true
		}
	}
}
