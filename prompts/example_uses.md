Both Conjuguer and Konjugieren have example uses of the frequency-ranked verbs plus a few more, in Conjuguer’s case. I’d like to have the same for Conjugar. The Conjuguer implementation is superior to the Konjugieren implementation in two ways that I’d like to preserve for Conjugar.

First, example extraction was much quicker and more token-efficient because I essentially pre-conjugated all verbs and pre-mined the corpora. For Konjugieren, subagents did a lot of duplicated and unnecessary work. ../Conjuguer/docs/literature-example-corpus.md documents the Conjuguer approach.

Second, Conjuguer has examples not only mostly from literature of the 18th to early 20th centuries but also, in many cases, from La Chanson de Roland. See ~/Desktop/VerbView.png . By tapping the button, the user can see *all* Chanson de Roland examples for certain verbs. 

The first step in this project is to set up the corpus. I would like your help identifying a Medieval Spanish equivalent of La Chanson de Roland. Then, I would like your help identifying 16th-to-early-20th-century works of Spanish literature, permissible-use Spanish-language government documents, and technology-focused sources.

The Claude in Chrome MCP is running. If WebSearch or WebFetch is blocked for either reading or download, use that MCP.

Side note on future plans: if a verb outside the ranked group has a medieval example, I would like that verb to have not only the medieval example but also a more-recent example and an etymology. As with Conjuguer, if no more-recent example is available in the corpus, you can fabricate one. 