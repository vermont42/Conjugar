We are working on Toreo por Amor, Conjugar's built-in, Donky Kong-inspired game. See blog_notes.md, recent commits, and the game code itself for context on the game. You can see a screenshot of the game's current state at ~/Desktop/game.png .

One level of the game is looking good. As I see it, there are three outstanding action items:

1. Add more obstacles that the bull sends towards the player. Currently, he only sends flags. Fireballs, for example, would be cool. The intent is to have five levels. Later levels will have more obstacles and perhaps power-ups.
2. Add scoring.
3. Add the final boss fight that the player must complete after completing five levels.
4. Add an end scene for when the player defeats the bull boss.

I'd like you to ideate on item 3. Ordinarily, boss fights involve players shooting projectiles at the boss and killing him. But Toreo por Amor is a family-friendly game, so I'd like a difference mechanic: the player has a *dance-off* with the boss. If the player wins the dance-off, the boss is impressed and releases the matador.

The problem is that I have no idea how the dance-off mechanic would look or operate. That is where I need your help. Please generate three ideas for the boss fight with dance. The player can currently move left and right or jump, but additional controls could be implemented for the dance-off. The bull can be further animated. I will pick a winning concept and have you iterate on that.

The mechanic can invole using emoji, for example musicial-note emoji, or generating new assets via Gemini Image or Blender. During the boss fight, the song represented by `Music.bossFight` will play.

In the course of your research, consult not only Conjugar's existing code, but also

* Drive the game using ios-build-verify to explore the current game
* Research existing game dance mechanics for inspiration - the Claude in Chrome MCP is running in case a page is blocked to WebFetch
* Consider the many (non-dance) game mechanics in Conjugar's sibling apps, Konjugieren, which lives at ~/Desktop/workspace/Konjugieren, and Conjuguer, which lives at ~/Desktop/workspace/Conjuguer . I am not asking you to adapt any of these, but they illustrate the sense of fun I am looking for. 
