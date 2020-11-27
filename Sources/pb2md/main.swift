//
//  main.swift
//  pbandj
//
//  Created by Josh Nichols on 11/25/20.
//

import Foundation
import Cocoa

let pasteboard = NSPasteboard.general

struct Pboard: Codable {
    var html: String?
    var text: String?
    var rtf: String?
}

var originalPboard = Pboard()

// get contents of general pasteboard
let typeHtml = NSPasteboard.PasteboardType.html
let typeText = NSPasteboard.PasteboardType.string
let rtfText = NSPasteboard.PasteboardType.rtf

if let s = NSPasteboard.general.string(forType:typeHtml) {
    originalPboard.html = s
}
if let s = NSPasteboard.general.string(forType: typeText) {
    originalPboard.text = s
}
if let s = NSPasteboard.general.string(forType: rtfText) {
    originalPboard.rtf = s
}

func rdf2html(string : String) -> String {
    let textUtilPipe = Pipe()
    let textUtilPipeHandle = textUtilPipe.fileHandleForWriting
    textUtilPipeHandle.write(string.data(using: .utf8)!)
    try! textUtilPipeHandle.close()

    let completePipe = Pipe()
    
    let textutil = Process()
    textutil.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    textutil.arguments = ["textutil", "-convert", "html", "-stdin", "-stdout"]
    textutil.standardInput = textUtilPipe
    textutil.standardOutput = completePipe
    
    do{
      try textutil.run()
      let data = completePipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: String.Encoding.utf8) {
        return output
        
      }
    } catch {}
    return ""
}

func html2markdown(string : String) -> String {
    let pandocPipe = Pipe()
    let pandocPipeHandle = pandocPipe.fileHandleForWriting
    pandocPipeHandle.write(string.data(using: .utf8)!)
    try! pandocPipeHandle.close()

    let completePipe = Pipe()
    
    let pandoc = Process()
    pandoc.executableURL = URL(fileURLWithPath: "/usr/local/bin/pandoc")
    pandoc.arguments = ["--from=html", "--to=markdown_strict"]
    pandoc.standardInput = pandocPipe
    pandoc.standardOutput = completePipe
    
    do{
      try pandoc.run()
      let data = completePipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: String.Encoding.utf8) {
        return output
      }
    } catch {}
    return ""
}

//print(dump(originalPboard))

var updatedPboard = Pboard()

if originalPboard.rtf != nil {
    print(originalPboard.rtf!)
    print("Converting rtf to html to md... ", terminator: "")
    updatedPboard.html = rdf2html(string: originalPboard.rtf!)
    updatedPboard.text = html2markdown(string: updatedPboard.html!)
    print("done")
} else if originalPboard.html != nil {
    print(originalPboard.html!)
    print("Converting html to md... ", terminator: "")
    updatedPboard.text = html2markdown(string: originalPboard.html!)
    print("done")
} else {
    print("Nothing to convert.")
}


// TODO Maybe check if originalPboard.text starts with HTML tags?

// only clear and update the pasteboard if something was
if updatedPboard.text != nil {
    print(updatedPboard.text!)
    
    pasteboard.clearContents()
    pasteboard.setString(updatedPboard.text!, forType: .string)
}
