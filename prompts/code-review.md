Please do a thorough review of the codebase. Look for bugs, code smells, code duplication, deprecated/outdated API use, concurrency gotchas, inelegant code, and any other shortcomings. In the prompts folder, output a Markdown file with a list of recommendations ranked highest impact to lowest. At the bottom of the file, propose an implementation sequence.

If you need to exercise Conjugar to analyze its behavior, use the ios-build-verify skill.

I recognize that there is code duplication between ModelBrowseView and VerbBrowseView. This is intentional.

Here is some context on Conjugar. I created the app in 2017 using UIKit. Recently, I converted Conjugar to SwiftUI and added some features. Recent development starts at commit fa251ef.

Conjugar has sibling apps for French- and German-verb conjugation. Those live at /Users/josh/Desktop/workspace/Conjuguer and /Users/josh/Desktop/workspace/Konjugieren , respectively.