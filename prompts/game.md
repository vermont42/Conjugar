The time has come to make a game launchable from Conjugar.

There is precedent. Three of my existing apps have built-in games. I'll say a few words about each. Please explore the codebases as you read about each game.

/Users/josh/Desktop/workspace/RaceRunner : I wrote this in 2017 (I think) using SpriteKit. The mechanic and gameplay are similar to Galaga in that waves of joggers and horses progress down the screen, firing bullets at the player, who can fire back. The user moves the player by tilting the iPhone. This game is extremely primitive, but it has an advantage over the other two: the joggers and horses are animated in that the game cycles through multiple jogger and horse images.

/Users/josh/Desktop/workspace/Konjugieren : Claude wrote this, with my input, in 2026 using pure SwiftUI. The main mechanic is also Galaga-inspired, in that the player, represented by a humanoid pretzel, shoots at waves of various types of enemies like German hats, cuckoo clocks, and dachsunds, who fire back. The user moves the player by tilting the iPhone. In addition to the main Galaga mechanic, there are many other mechanics inspired by 80s videogames. These are described in the localized String whose key is Info.gameText.

/Users/josh/Desktop/workspace/Conjuguer : Claude wrote this, with my input, in 2026 using pure SwiftUI. The main mechanic is also Galaga-inspired, in that the player, represented by an Arc de Triomphe, shoots at various types of enemies like croissants, berets, and roosters. The user moves the player by tapping buttons at the bottom-left corner of the screen. In addition to the main Galaga mechanic, there are many other mechanics inspired by 80s videogames. I haven't documented these, but the code is in the Game folder.

I've made the following decisions about Conjugar's game. For simplicity, I'll use the present tense for these decisions.

1. The mechanic is entirely different: Donkey Kong-inspired. The player is a flamenco dancer. The screen has a series of platforms connected by ladders. The player starts on the bottom platform and move across platforms and up/down ladders using four buttons at the bottom-left corner of the screen. There is also a jump button. The enemy is a single bull on the topmost platform. Next to the bull is a bullfighter that the bull kidnapped. The bull sends flags of various Spanish-speaking countries down the platforms, towards the player. (Donkey Kong equivalent: barrels.) The player ascends the map towards the bull. The first four times the player reaches the bull, the bull escapes, taking the bullfighter. The fifth time the player reaches the bull, the player somehow fights the bull in a final scene. If the player defeats the bull, the player rescues the bullfighter, winning the game. At various points on the screen are power-up bullfighting capes. (Donkey Kong equivalent: hammer.) The player can use these to smash flags. Each flag that touches the player takes 25% of the player's health.

2. Graphics are way better than in the existing games. As in RaceRunner, there is animation, both of the player as she is walking left/right and jumping and of the bull as it is walking and climbing. The frames of the animation are produced by some tool like Blender, which I believe has an MCP or CLI. I'll need your help both designing the assets and using Blender (or some other tool) to generate them. For now, the bullfighter needs only one frame. Producing an animation is a hard problem. For RaceRunner, I drew the jogger frames by hand and traced photos from The Horse in Motion [photographs](https://en.wikipedia.org/wiki/The_Horse_in_Motion). I believe that, in the realm of game development, there are concepts of ragdolls or wireframes that are used for animation, but I need a lot of help.

3. The background music is a permissive-use flamenco song. I'll need help finding that.

4. The game is launced from the Settings tab, as in the other apps.

5. All assets have a color scheme inspired by Conjugar's.

There will be more features in the game, but those can be specified later.

The biggest improvement in this game, compared to the others, is the animation, which Conjuguer and Konjugieren entirely lack. As a starting point, I would like you help researching the asset-generation and animation processes. Is Blender the right tool? How can a dancer or bull asset be animated? I have Gemini to generate images, but I suspect that Gemini can't be controlled in such a way as to specify exact frames of an animation.

You will likely reach for WebSearch and WebFetch for your research, which is appropriate. But some sites might be blocked for those tools. If they are, fall back to the Claude in Chrome MCP, which is running.

With respect to architecture/stack, I like Conjguer's and Konjugieren's use of SwiftUI, which is performant and understandable to me. Apple has essentially deprecated SpriteKit, de facto if not de jure. A question I have is whether SwiftUI would remain performant with animated frames, which the existing games don't have.