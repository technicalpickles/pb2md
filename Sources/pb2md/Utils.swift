import Cocoa

struct Pboard: Codable {
    var html: String?
    var text: String?
    var rtf: String?
}

func getCurrentPasteboard() -> Pboard {
  var originalPboard = Pboard()
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

  return originalPboard
}

func rtf2htmlProcess() -> Process {
  let textutil = Process()
  textutil.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  textutil.arguments = ["textutil", "-convert", "html", "-stdin", "-stdout"]

  return textutil
}

func rdf2html(string : String) -> String {
  let input = Pipe()

  let inputHandle = input.fileHandleForWriting
  inputHandle.write(string.data(using: .utf8)!)
  try! inputHandle.close()

  let completePipe = Pipe()
  let textutil = rtf2htmlProcess()
  textutil.standardInput = input
  textutil.standardOutput = completePipe
    
  do {
    try textutil.run()
    let data = completePipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: String.Encoding.utf8) {
      return output
      
    }
  } catch {}
  return ""
}

func html2markdownProcess() -> Process {
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

  return pandoc
}

func html2markdown(string : String) -> String {
    let pandocPipe = Pipe()
    let pandocPipeHandle = pandocPipe.fileHandleForWriting
    pandocPipeHandle.write(string.data(using: .utf8)!)
    try! pandocPipeHandle.close()

    let completePipe = Pipe()
    
    let pandoc = html2markdownProcess()
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

func markdownLintProcess() -> Process {
  let markdownlint = Process()
  markdownlint.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  markdownlint.arguments = [
      "markdownlint",
      "--stdin",
      "--fix"
  ]
  return markdownlint
}

func markdownLint(string : String) -> String {
    let markdownlintPipe = Pipe()
    let markdownlintPipeHandle = markdownlintPipe.fileHandleForWriting
    markdownlintPipeHandle.write(string.data(using: .utf8)!)
    try! markdownlintPipeHandle.close()

    let completePipe = Pipe()
    
    let markdownlint = markdownLintProcess()
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


func blockquoteProcess() -> Process {
  let sed = Process()
  sed.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  sed.arguments = [
    "sed",
    "s/^/> /",
  ]

  return sed
}

// func pipeline(pboard : Pboard) -> Array<Process> {
//   var processes = Array<Process>()

//   var input = String()
//   if pboard.rtf != nil {
//     processes.append(rtf2htmlProcess())
//     input = pboard.rtf!
//   }
  
//   let text = pboard.text!
//   // first character < ? assume HTML
//   if (text[text.startIndex] == "<") {
//   }

//   if pboard.rtf != nil || pboard.html != nil || text[text.startIndex] == "<"

//   return processes
// }

func blockquote(string : String) -> String {
    var lines = [String]()
    string.enumerateLines { (line, stop) -> () in
        lines.append("> \(line)")
    }

    return lines.joined(separator: "\n")
}