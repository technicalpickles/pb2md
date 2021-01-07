//  Created by Josh Nichols on 11/25/20.

import Cocoa
import Foundation
import Darwin

let addBlockquotes = CommandLine.arguments.contains("--blockquote")
let verbose = CommandLine.arguments.contains("--verbose")

var updatedPboard = Pboard()
let originalPboard = getCurrentPasteboard()

if originalPboard.rtf != nil {
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
    
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(updatedPboard.text!, forType: .string)
} else {
    print("Nothing to do.")
}
