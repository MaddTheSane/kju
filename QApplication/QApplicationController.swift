//
//  QApplicationController.swift
//  Q
//
//  Created by C.W. Betts on 10/19/15.
//
//

import Cocoa

class QApplicationController : NSObject, NSApplicationDelegate {
	private var uniqueDocumentID: Int32 = 7
	override init() {
		Q_DEBUG("init");
		
		super.init()
		
		let defaults = NSUserDefaults.standardUserDefaults()
		//preferences
		defaults.registerDefaults([
			"enableLogToConsole": false,	// disable log to console
			"yellow": true,					// yellow
			"showFullscreenWarning": true,	// showFullscreenWarning
			"knownVMs": [String]()			// known VMs
			])
		
		// remove obsolete entries form old preferences
		func checkAndRemove(keys: [String]) {
			for key in keys {
				if defaults.objectForKey(key) != nil {
					defaults.removeObjectForKey(key)
				}
			}
		}
		
		checkAndRemove(["enableOpenGL", "display", "enableCheckForUpdates", "dataPath"])
		// TODO: Sparclekey for userdefaults
		
		// add necessary entries to old preferences
		let fm = NSFileManager.defaultManager()
		if defaults.objectForKey("dataPath") == nil {
			let docURL = try! fm.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false).URLByAppendingPathComponent("QEMU", isDirectory: true)
			defaults.setObject(docURL.path, forKey: "dataPath")
		}
		
		// create PC directory
		if fm.fileExistsAtPath(defaults.stringForKey("dataPath")! + "/") == false {
			do {
				try fm.createDirectoryAtPath(defaults.stringForKey("dataPath")!, withIntermediateDirectories: true, attributes: nil)
			} catch let error as NSError {
				let alert = NSAlert(error: error)
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(USEC_PER_SEC * 20)), dispatch_get_main_queue(), { () -> Void in
					alert.runModal()
				})
			}
		}
	}
	
	//MARK: overriding NSDocumentController & NSApp Methods

	func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
		Q_DEBUG("applicationShouldOpenUntitledFile");

		// we want no untitled doc
		return false
	}
	
	func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
		NSUserDefaults.standardUserDefaults().synchronize()
		NSDocumentController.sharedDocumentController().closeAllDocumentsWithDelegate(self, didCloseAllSelector: "documentController:didCloseAll:contextInfo:", contextInfo: nil)
		
		return .TerminateLater
	}
	
	@objc(documentController:didCloseAll:contextInfo:) private func documentController(docController: NSDocumentController, didCloseAll: Bool, contextInfo: UnsafeMutablePointer<Void>) {
		Q_DEBUG("QApplicationController: documentController: didCloseAll");
		
		NSApp.replyToApplicationShouldTerminate(true)
	}
	
	@IBAction func openDocument(sender: AnyObject?) {
		Q_DEBUG("openDocument");
		
		let panel = NSOpenPanel()
		panel.allowedFileTypes = ["qvm", "ch.kberg.Q.vm"]
		if let pcData = userDefaults.stringForKey("pcData") {
			let dirURL = NSURL(fileURLWithPath: pcData)
			panel.directoryURL = dirURL
		}
		panel.beginWithCompletionHandler { (returnCode) -> Void in
			Q_DEBUG("openPanelDidEnd");
			
			if returnCode == NSOKButton {
				if (panel.URLs.count < 1) {
					return;
				}
				let path = panel.URLs[0]
				let documentController = NSDocumentController.sharedDocumentController()
				
				if documentController.documentForURL(path) != nil {
					NSLog("Document is already open");
					//Todo: show the document
				} else {
					// open the document
					do {
						let document = try documentController.makeDocumentWithContentsOfURL(path, ofType: "QVM")
						documentController.addDocument(document)
						document.makeWindowControllers()
						document.showWindows()
					} catch let error as NSError {
						NSLog("Document was not created, error %@", error);
					}
				}
			}
		}
	}
	
	func leaseAUniqueDocumentID(sender: AnyObject) -> Int32 {
		Q_DEBUG("leaseAUniqueDocumentID");
		
		uniqueDocumentID++;
		
		return uniqueDocumentID;
	}
	
	//Uh... okay.
	var userDefaults: NSUserDefaults {
		return NSUserDefaults.standardUserDefaults()
	}
}
