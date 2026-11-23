//
//  main.swift
//  ConjugationMapTool
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// ConjugationMapTool: the build-time writer of the conjugation map, and the writer of the
// corpus pipelines' forms.json and forms_all.json.
//
// Consumes: verbModelMap.xml, given as a path.
// Produces: the app's ConjugationMap.lzfse (see Conjugar/Models/ConjugationMap.swift for the
//           format) and, when asked, corpus/working/forms.json (the 1,000 most common verbs) and
//           forms_all.json (every verb), which the Python pipelines read.
//
// Run:      ConjugationMapTool --verb-map <verbModelMap.xml> \
//             [--map <out.lzfse>] [--forms-json <out.json>] [--forms-all-json <out.json>] \
//             [--cells-json <out.json>]
//
// The app target's "Generate Conjugation Map" build phase runs this with --map, writing straight
// into the app bundle. Xcode runs that phase only when one of its declared inputs is newer than
// its output: verbModelMap.xml and this tool's executable. The executable stands in for every
// engine source, because Xcode relinks it whenever one of the files it compiles changes, and
// leaves it untouched otherwise.
//
// For the two JSON files, run scripts/write_forms_json.sh, which builds this target and calls it
// with the right paths. Until 2026-11-22 they came from a disabled test harness,
// CorpusFormsDumpTests, which this tool replaced.
//
// --cells-json writes every form with its cells (CellsJSON.swift) for scripts/count_tenses.py,
// which builds this target and runs it itself.
//
// The tool compiles the app's own engine sources (the membership exceptions on the Models folder
// in project.pbxproj list them) plus ConjugationMap.swift, so the map, the app's display, and
// the JSON files all come from one engine. The engine is nonisolated and reaches nothing of the
// app's but VerbMap, which reads verbModelMap.xml from VerbMap.resourceURLOverride here, since a
// command-line tool has no bundle. If a build of this target fails with "cannot find 'X' in
// scope", a file the tool compiles has started reaching app-only code (L, Current, Settings):
// move that member to a file the tool does not compile rather than adding the file to the tool.

import Foundation

/// The command line, as a dictionary of flag to path. Every flag takes exactly one value.
private func parseArguments() -> [String: String] {
  var values: [String: String] = [:]
  var remaining = CommandLine.arguments.dropFirst()
  while let flag = remaining.popFirst() {
    guard flag.hasPrefix("--"), let value = remaining.popFirst() else {
      fail("Expected --flag value pairs, got \(flag).")
    }
    values[flag] = value
  }
  return values
}

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("error: ConjugationMapTool: \(message)\n".utf8))
  exit(1)
}

/// The JSON the corpus pipelines read, `{ "<form>": ["<infinitive>", …] }`, as the harness wrote
/// it: forms of two or more letters (single letters are noise in a corpus), infinitives sorted,
/// keys sorted, pretty-printed. A compound tense or a negative command adds nothing, since its
/// last word is a participle or a subjunctive the map already holds.
private func formsJSON(_ map: ConjugationMap, verbs: Set<String>) throws -> Data {
  var forms: [String: [String]] = [:]
  for (form, entries) in map.entriesByForm where form.count >= 2 {
    let infinitives = entries.map(\.infinitive).filter(verbs.contains)
    if !infinitives.isEmpty {
      forms[form] = infinitives.sorted()
    }
  }
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  return try encoder.encode(forms)
}

/// The usage-ranked set the example-uses pipeline mines for forms.json.
private let usageRankedCount = 1000

let arguments = parseArguments()
guard let verbMapPath = arguments["--verb-map"] else {
  fail("--verb-map is required.")
}
let mapPath = arguments["--map"]
let formsJSONPath = arguments["--forms-json"]
let formsAllJSONPath = arguments["--forms-all-json"]
let cellsJSONPath = arguments["--cells-json"]
if mapPath == nil && formsJSONPath == nil && formsAllJSONPath == nil && cellsJSONPath == nil {
  fail("Nothing to write. Pass --map, --forms-json, --forms-all-json, --cells-json, or a combination.")
}

VerbMap.resourceURLOverride = URL(fileURLWithPath: verbMapPath)
let verbs = VerbMap.shared.entries
if verbs.isEmpty {
  fail("Parsed no verbs from \(verbMapPath). Check the path.")
}

let map = ConjugationMap.build()

do {
  if let mapPath {
    // Not .atomic: an atomic write creates a temporary file beside the output, and Xcode's
    // script sandbox, if enabled, permits writing only the declared output.
    try map.compressed().write(to: URL(fileURLWithPath: mapPath))
  }
  if let formsJSONPath {
    let ranked = Set(verbs.values.filter { $0.frequencyRank <= usageRankedCount }.map(\.infinitive))
    try formsJSON(map, verbs: ranked).write(to: URL(fileURLWithPath: formsJSONPath))
  }
  if let formsAllJSONPath {
    try formsJSON(map, verbs: Set(verbs.keys)).write(to: URL(fileURLWithPath: formsAllJSONPath))
  }
  if let cellsJSONPath {
    try CellsJSON.data(map).write(to: URL(fileURLWithPath: cellsJSONPath))
  }
} catch {
  fail("Could not write: \(error)")
}

print("ConjugationMapTool: \(map.entriesByForm.count) forms from \(verbs.count) verbs")
