I'd like you to write a plan to address item 15 / step 9 in prompts/code-reiew-recommendations-2.md .

Do not write any code. Another session is coding item 14 / step 8. Instead, just write the plan in the prompts folder.

Use ios-build-verify to explore the current state of the iPad interface, which is not great, aside from the game. Think about ways another session could improve the iPad interface. Conjugar's sibling apps, Konjugieren and Conjuguer, have great iPad support. Use them for inspiration. Those apps live in ../Konjugieren and ../Conjuguer , respectively. Here are screenshots of both apps' iPad support:

/Users/josh/Desktop/workspace/Konjugieren/docs/screenshots/version_2/iPad_English
/Users/josh/Desktop/workspace/Conjuguer/docs/screenshots/version_3/iPad_English

The plan should be multi-phase so it can be implemented across multiple sessions. As an early step of the plan, have the implementing session implement any shared components that would be useful across screens.

The other session might launch the iPhone simulator via ios-build-verify. You should be able to launch the iPad simulator without conflicting. If there are problems because of the other session's work, let me know.
