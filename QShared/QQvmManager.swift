//
//  QQvmManager.swift
//  Q
//
//  Created by C.W. Betts on 10/20/15.
//
//

import Foundation

final class QQvmManager : NSObject {
	static let sharedQvmManager = QQvmManager()
	
	private override init() {
		super.init()
	}
	
	func saveVMConfiguration(VM1: [String: AnyObject]) -> Bool {
		var VM = VM1
		Q_DEBUG("saveVMConfiguration \(VM)");
		
		//NSMutableDictionary *temporary;
		
		let temporary = VM.removeValueForKey("Temporary")! // don't store temporary items (URL can't be stored in Propertylist anyways)
		
		if let data = try? NSPropertyListSerialization.dataWithPropertyList(VM, format: .XMLFormat_v1_0, options: 0) {
			VM["Temporary"] = temporary // reenter Temporary
			var toWriteURL = (VM["Temporary"] as! [NSObject: AnyObject])["URL"] as! NSURL
			toWriteURL = toWriteURL.URLByAppendingPathComponent("configuration.plist")
			if data.writeToURL(toWriteURL, atomically: true) {
				return true
			}
		}
		return false;
	}
	
	func loadVMConfiguration(filepath: NSString) -> NSMutableDictionary? {
		Q_DEBUG("loadQVM: \(filepath)");

		if let data = NSData(contentsOfFile: filepath.stringByAppendingPathComponent("configuration.plist")) {
			var tempVM = try! NSPropertyListSerialization.propertyListWithData(data, options: .MutableContainersAndLeaves, format: nil) as! NSMutableDictionary as NSDictionary as! [String: AnyObject]

			// upgrade Version 0.1.0.Q to 0.2.0.Q
			if tempVM["Version"] as? String == "0.1.0.Q" {
				let lookForArguments = ["-snapshot", "-nographic", "-audio-help", "-localtime", "-full-screen", "-win2k-hack", "-usb", "-s", "-S", "-d", "-std-vga"];
				var arguments = ""
				for key in (tempVM["Arguments"] as! [String]) {
					if let aVar = (tempVM["Arguments"] as! [String: AnyObject])[key] {
						if key == "-net" && (aVar as? String) == "user" {
							arguments += " -net nic"
						}
						if lookForArguments.contains(key) {
							arguments += " \(key)"
						} else {
							arguments += " \(key) \(aVar as! String)"
						}
					}
				}
				tempVM["Arguments"] = arguments;
				tempVM["Version"] = "0.2.0.Q";
			}
			
			// upgrade Version 0.2.0.Q to 0.2.1.Q (i.e. use doublequotes on all commands and paths)
			if tempVM["Version"] as? String == "0.2.0.Q" {
				let lookForArguments = ["-hda", "-hdb", "-hdc", "-hdd", "-fda", "-fdb", "-cdrom", "-append", "-kernel", "-initrd", "-smb"];
				let singleArguments = (tempVM["Arguments"] as! String).componentsSeparatedByString(" ").filter({
					return $0 != ""
				})
				
				var arguments: String = {
					let aName = (tempVM["PC Data"] as! [String: AnyObject])["name"]
					
					return "-name \"\(aName!)\" "
				}()
				var option = ""
				var argument = ""
				
				for tmpArgument in singleArguments {
					if tmpArgument.characters.first! != "-" { // part of argument
						if argument.isEmpty {
							argument = tmpArgument
						} else {
							argument += " " + tmpArgument
						}
					} else { // key
						if !option.isEmpty { // handle previous key
							arguments += option + " "
							if lookForArguments.contains(option) { // path or command
								arguments += "\"\(argument)\" "
								argument = ""
							} else if !argument.isEmpty {
								arguments += argument + " "
								argument = ""
							}
							option = ""
						}
						option = tmpArgument
					}
				}
				if !option.isEmpty { // handle last option, argument pair
					arguments += option + " "
					if lookForArguments.contains(option) { // path or command
						arguments += "\"%\(argument)\""
					} else {
						arguments += argument
					}
				}
				// remove obsolte keys
				var pcData = (tempVM["PC Data"] as! [String: AnyObject])
				pcData.removeValueForKey("name")
				tempVM["PC Data"] = pcData
				
				tempVM["Arguments"] = arguments;
				tempVM["Version"] = "0.3.0.Q";
			}
			// get rid of old temporary items and add new
			if tempVM["Temporary"] != nil {
				tempVM.removeValueForKey("Temporary")
			}
			var tempor = [NSObject: AnyObject]()
			
			// exploded arguments
			tempor["explodedArguments"] = explodeVMArguments(tempVM["Arguments"] as! String)

			
			// url
			tempor["URL"] = NSURL(fileURLWithPath: filepath as String)
			
			tempVM["Temporary"] = tempor
			return NSMutableDictionary(dictionary: tempVM);
		}
		
		return nil
	}
	
	func explodeVMArguments(argumentsString: String) -> [String] {
		Q_DEBUG("explodeVMArguments: \(argumentsString)");
		
		//argumentsString = @"   -emptySwitchWithWhite  -emptySwitch -test1 escaped\\ -fakeSwitch\\ example -test2 \"doublequoted -fakeSwitch example\" -test3 'singlequoted -fakeSwitch example' nokey\\ escaped\\ 'singlequoted '\"doublequoted ' -fakeSwitch ' example\"";
		
		var argumentsArray = [String]()
		var quoteChar: Character?
		var argument = [Character]()
		
		var isEscapedChar = false;
		var inQuote = false;
		var inSwitch = false;
		var inArgument = false;
		var key = ""
		
		for aChar in argumentsString.characters {
			switch aChar {
			case " ":
				if isEscapedChar { // add escaped whitespace
					argument.append(aChar)
					isEscapedChar = false;
				} else if inQuote { // if we are inside a quote, accept white space
					argument.append(aChar)
				} else if inSwitch { // else, this whitespace is a separator
					key = String(argument)
					// clear the arguments
					argument = []
					inSwitch = false;
				} else if inArgument {
					argumentsArray.append(key)
					argumentsArray.append(String(argument))
					// clear the arguments
					argument = []
					key = "";
					inArgument = false;
				} else {
					// ignore doublewhitespace
				}
				
			case "-":
				if !inArgument && !inSwitch { // start of a switch
					if !key.isEmpty { // store previous switch-only argument
						argumentsArray.append(key)
						key = "";
					}
					inSwitch = true;
				}
				argument.append(aChar)
				
			case "\"":
				if (isEscapedChar) { // ignore escaped "
					argument.append("\\"); // we are only intrested in escaped whitespace, readd escape
					isEscapedChar = false;
					argument.append(aChar)
				} else {
					if inQuote {
						if quoteChar == "\"" { // remove "
							inQuote = false;
						} else { // ignore "
							argument.append(aChar)
						}
					} else {
						inQuote = true;
						quoteChar = "\"";
					}
				}
				
			case "'":
				if isEscapedChar { // ignore escaped '
					argument.append("\\") // we are only intrested in escaped whitespace, readd escape
					isEscapedChar = false;
					argument.append(aChar)
				} else {
					if inQuote {
						if quoteChar == "'" { // remove '
							inQuote = false;
						} else { // ignore '
							argument.append(aChar)
						}
					} else {
						inQuote = true;
						quoteChar = "'";
					}
				}
				
			case "\\":
				if !inQuote && !isEscapedChar { // remove /
					isEscapedChar = true;
				} else { // ignore /
					argument.append(aChar)
				}
				
			default:
				if !inSwitch && !inArgument { //start of new argument
					inArgument = true;
					if key.isEmpty {
						key = "-hda"; // only argument without key is -hda
					}
				}
				if isEscapedChar {
					argument.append("\\") // we are only intrested in escaped whitespace, readd escape
					isEscapedChar = false;
				}
				argument.append(aChar)
			}
		}
		
		if inSwitch { // switch
			argumentsArray.append(String(argument))
		} else if inArgument { // switch and argument
			argumentsArray.append(key)
			argumentsArray.append(String(argument))
		} else {
			// must have been an empty string
		}
		
		return argumentsArray
	}
}
