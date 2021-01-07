//
//  main.swift
//  pbandj
//
//  Created by Josh Nichols on 11/25/20.
//

import Foundation
import Cocoa
import Darwin

let pasteboard = NSPasteboard.general

let addBlockquotes = CommandLine.arguments.contains("--blockquote")
let verbose = CommandLine.arguments.contains("--verbose")

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
    pandoc.arguments = [
        // custom lua filter to clean out more stuff, see it for details
        "--lua-filter=/Users/technicalpickles/src/pb2md/pandoc/sparse-markdown.lua",
        // use native_divs and native_spans
        // this will help keep out divs and spans, and classes on them
        "--from=html-native_divs-native_spans",
        // markdown strict should help keep a lot of random elements out of the output
        "--to=markdown_strict"
    ]
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

func markdownLint(string : String) -> String {
    let markdownlintPipe = Pipe()
    let markdownlintPipeHandle = markdownlintPipe.fileHandleForWriting
    markdownlintPipeHandle.write(string.data(using: .utf8)!)
    try! markdownlintPipeHandle.close()

    let completePipe = Pipe()
    
    let markdownlint = Process()
    markdownlint.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    markdownlint.arguments = [
        "markdownlint",
        "--stdin",
        "--fix"
    ]
    markdownlint.standardInput = markdownlintPipe
    markdownlint.standardOutput = completePipe
    
    do{
      try markdownlint.run()
      let data = completePipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: String.Encoding.utf8) {
        return output
      }
    } catch {}
    return ""
}

func blockquote(string : String) -> String {
    var lines = [String]()
    string.enumerateLines { (line, stop) -> () in
        lines.append("> \(line)")
    }

    return lines.joined(separator: "\n")
}

//print(dump(originalPboard))

var updatedPboard = Pboard()

if originalPboard.rtf != nil {
    // if (verbose) {
    //     print(originalPboard.rtf!)
    // }

    updatedPboard.html = rdf2html(string: originalPboard.rtf!)
    updatedPboard.text = html2markdown(string: updatedPboard.html!)
    print("Converted RTF to HTML to Markdown.")
} else if originalPboard.html != nil {
    if (verbose) {
        print(originalPboard.html!)
    }

    updatedPboard.text = html2markdown(string: originalPboard.html!)
    print("Converted HTML to Markdown")
} else if (originalPboard.text != nil) {
    let text = originalPboard.text!
    // first character < ? assume HTML
    if (text[text.startIndex] == "<") {
        print("Converted HTML (stored as text) to Markdown")
        updatedPboard.text = html2markdown(string: originalPboard.text!)
    } else if (addBlockquotes) {
        print("Added blockquotes to Markdown")
        // quoting is handled at the end
        updatedPboard.text = originalPboard.text
    }
} else {
    print("Nothing to convert.")
    exit(1)
}

// only clear and update the pasteboard if something was
if updatedPboard.text != nil {
    if (addBlockquotes) {
        updatedPboard.text = blockquote(string: updatedPboard.text!)
    }
    updatedPboard.text = markdownLint(string: updatedPboard.text!)

    if (verbose) {
        print(updatedPboard.text!)
    }
    
    pasteboard.clearContents()
    pasteboard.setString(updatedPboard.text!, forType: .string)
} else {
    print("Nothing to do.")
}
