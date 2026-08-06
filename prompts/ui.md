The time has come to migrate Conjugar to SwiftUI, the framework that its brethren Conjuguer and Konjugieren use.

Conjuguer is a French-verb app that lives in /Users/josh/Desktop/workspace/Conjuguer .

Konjugieren is a German-verb app that lives in /Users/josh/Desktop/workspace/Konjugieren .

The naive approach would be to migrate Conjugar's screens directly to SwiftUI. But, using the skill `ios-design-agent-skill`, I identified many problems with the UIs of Konjugieren and Conjuguer, which were originally similar to that of Conjugar.

Here are sugggestions for improving Conjuguer's UI, all implemented: /Users/josh/Desktop/workspace/Conjuguer/docs/conjuguer-ui-issues.md

Here are sugggestions for improving Konjugieren's UI, all implemented: /Users/josh/Desktop/workspace/Konjugieren/docs/ui-audit.md

I documented my use of `ios-design-agent-skill` for Konjugieren [here](https://racecondition.software/blog/ios-design-agent-skill/).

Before we migrate Conjugar to SwiftUI, I recommend the following:

1. Identify and codify a design system for Conjugar. This will involve creating light and dark color assets like Konjugieren has.
2. Identify shortcomings in Conjugar's current UI, as identified by ios-design-agent-skill . Use `run-in-simulator` skill to exercise Conjugar.
3. Code the modifiers and other SwiftUI shared code that the migration will use.

When these steps are complete, Conjugar will be ready for the SwiftUI migration. A by-product of the migration is that not only will Conjugar's UI look awesome, but it will also have proper light and dark mode.

Do you agree with this approach?