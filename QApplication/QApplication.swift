//
//  QApplication.swift
//  Q
//
//  Created by C.W. Betts on 10/19/15.
//
//

import Cocoa

func Q_DEBUG(@autoclosure message: () -> String, file: StaticString = __FILE__, line: Int = __LINE__) {
	#if DEBUG
		let aMess = message()
		NSLog("[%@ %@] (%D)", (file.stringValue as NSString).lastPathComponent, aMess, line)
	#else
	//do nothing
	#endif
}

class QApplication : NSApplication {
	let applicationController = QApplicationController()
	override init() {
		super.init()
		delegate = applicationController
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		delegate = applicationController
	}
	
	override func sendEvent(anEvent: NSEvent) {
		
		let document = NSDocumentController.sharedDocumentController().currentDocument as? QDocument
		// handle command Key Combos
		if ((anEvent.type == .KeyDown) && (anEvent.modifierFlags.contains(.CommandKeyMask))) {
			switch anEvent.keyCode {
				
				// fullscreen
			case 3: // cmd+f
				document?.screenView.toggleFullScreen()
				
				// fullscreen toolbar
			case 11: // cmd+b
				if let aDoc = document where aDoc.screenView.fullscreen {
					aDoc.screenView.fullscreenController.toggleToolbar()
				}

			default:
				super.sendEvent(anEvent)
			}
			// handle mouseGrabed
		} else if (document?.screenView.mouseGrabed ?? false) {
			document?.screenView.handleEvent(anEvent)
			// default
		} else {
			super.sendEvent(anEvent)
		}
	}
}
