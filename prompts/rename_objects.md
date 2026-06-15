In [this article](https://www.martinfowler.com/bliki/TestDouble.html), Martin Fowler introduced the concept of test doubles: dummies, fakes, stubs, spies, and mocks. In the following app, I used Fowler's naming consistently: /Users/josh/Desktop/workspace/iOSExpert/solution-wrap-up/CatFancy-final

Unfortunately, names for protocols defining behavior in Conjugar don't following Fowler's naming conventions. Also, the names used mean that related files don't sort near each other in Xcode's Project Navigator. For example, we have GetterSetter (fine) but also DictionaryGetterSetter and UserDefaultsGetterSetter. Those latter two should be GetterSetterFake and GetterSetterReal, respectively, as they are in CatFancy-final.

I am providing here a list of protocol objects defining behavior. Two of the names are fine, but I will suggest two renames. I would like you to rename the conformances of those protocols in the CatFancy-final spirit. In naming the test-double files, use the Fowler definitions. For example, DictionaryGetterSetter and UserDefaultsGetterSetter should become GetterSetterFake and GetterSetterReal, respectively. I am okay with the loss of the "UserDefaults" information from the rename of UserDefaultsGetterSetter. The fact that it is a real implementation is what matters.

CommunGetter
GameCenterable -> GameCenter
Locale (fine, but check for collisions with system APIs)
ReviewPromptable -> ReviewPrompter

I believe that this list is exhaustive, but please let me know if I missed any behavior protocols with real and test-double conformances.

Before you rename anything, please propose the new names to me for verification.