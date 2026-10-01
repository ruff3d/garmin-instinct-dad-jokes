import Toybox.Lang;
import Toybox.Test;

(:test)
function acceptsValidJoke(logger as Test.Logger) as Boolean {
    var joke = JokeResponse.parse(200, {"status" => 200, "joke" => " Dad\n joke. "});
    Test.assert(joke != null && (joke as String).equals("Dad joke."));
    return true;
}

(:test)
function rejectsFailedAndMalformedResponses(logger as Test.Logger) as Boolean {
    Test.assert(JokeResponse.parse(503, {"joke" => "Error"}) == null);
    Test.assert(JokeResponse.parse(200, null) == null);
    Test.assert(JokeResponse.parse(200, "not json") == null);
    Test.assert(JokeResponse.parse(200, {"status" => 500, "joke" => "Error"}) == null);
    Test.assert(JokeResponse.parse(200, {"status" => 200, "joke" => 42}) == null);
    Test.assert(JokeResponse.parse(200, {"status" => 200, "joke" => " \r\n\t "}) == null);
    return true;
}

(:test)
function rejectsOversizedJokes(logger as Test.Logger) as Boolean {
    var text = "";
    for (var i = 0; i < 513; i += 1) { text += "x"; }
    Test.assert(JokeResponse.parse(200, {"status" => 200, "joke" => text}) == null);
    return true;
}

(:test)
function retainsJokeOnFailedRefresh(logger as Test.Logger) as Boolean {
    var state = new JokeState(["Saved joke."] as Array<String>);
    state.receive(null);
    Test.assert((state.current() as String).equals("Saved joke."));
    Test.assertEqual(state.offline, true);
    state.receive("Fresh joke.");
    Test.assert((state.current() as String).equals("Fresh joke."));
    Test.assertEqual(state.offline, false);
    return true;
}

(:test)
function wrapsAtWordsAndSplitsLongWords(logger as Test.Logger) as Boolean {
    var font = new TestFont();
    var lines = JokeText.wrap("Why did the dad laugh?", 8, font.method(:measure));
    Test.assertEqual(lines.size(), 3);
    Test.assertEqual(lines[0], "Why did");
    Test.assertEqual(lines[1], "the dad");
    Test.assertEqual(lines[2], "laugh?");
    lines = JokeText.wrap("abcdefghij", 4, font.method(:measure));
    Test.assertEqual(lines.size(), 3);
    Test.assertEqual(lines[0], "abcd");
    Test.assertEqual(lines[2], "ij");
    return true;
}

(:test)
function keepsAWordThatExactlyFits(logger as Test.Logger) as Boolean {
    var font = new TestFont();
    var lines = JokeText.wrap("Hi there all", 8, font.method(:measure));
    Test.assertEqual(lines.size(), 2);
    Test.assertEqual(lines[0], "Hi there");
    Test.assertEqual(lines[1], "all");
    return true;
}

(:test)
function wrapsToEachScreenRowWidth(logger as Test.Logger) as Boolean {
    var font = new TestFont();
    var lines = JokeText.wrapRows("abcdef ghij klmnop", [4, 8] as Array<Number>,
                                  font.method(:measure));
    Test.assertEqual(lines.size(), 4);
    Test.assertEqual(lines[0], "abcd");
    Test.assertEqual(lines[1], "ef ghij");
    Test.assertEqual(lines[2], "klmn");
    Test.assertEqual(lines[3], "op");
    return true;
}

(:test)
function rotatesRowWidthsByScrollOffset(logger as Test.Logger) as Boolean {
    var widths = [10, 20, 30] as Array<Number>;
    // Arrays compare by reference in Monkey C, so check element by element.
    var cases = {
        0 => [10, 20, 30] as Array<Number>,
        1 => [30, 10, 20] as Array<Number>,
        2 => [20, 30, 10] as Array<Number>,
        3 => [10, 20, 30] as Array<Number>
    };
    var offsets = cases.keys();
    for (var i = 0; i < offsets.size(); i += 1) {
        var offset = offsets[i] as Number;
        var expected = cases.get(offset) as Array<Number>;
        var actual = JokeText.rotateWidths(widths, offset);
        Test.assertEqual(actual.size(), expected.size());
        for (var k = 0; k < expected.size(); k += 1) {
            Test.assertEqual(actual[k], expected[k]);
        }
    }
    return true;
}

(:test)
function splitsSetupFromPunchline(logger as Test.Logger) as Boolean {
    var parts = JokeText.split("Why did the dad laugh? Because it was funny.");
    Test.assertEqual(parts.size(), 2);
    Test.assert(parts[0].equals("Why did the dad laugh?"));
    Test.assert(parts[1].equals("Because it was funny."));

    parts = JokeText.split("I'm afraid for the calendar. Its days are numbered.");
    Test.assertEqual(parts.size(), 2);
    Test.assert(parts[0].equals("I'm afraid for the calendar."));
    Test.assert(parts[1].equals("Its days are numbered."));

    Test.assertEqual(JokeText.split("One sentence only").size(), 1);
    return true;
}

(:test)
function keepsOnlyNewestJoke(logger as Test.Logger) as Boolean {
    var state = new JokeState(null);
    state.receive("One.");
    state.receive("Two.");
    Test.assert((state.current() as String).equals("Two."));
    Test.assertEqual(state.jokes.size(), 1);
    return true;
}

(:test)
function confirmRevealsThenRequestsNextJoke(logger as Test.Logger) as Boolean {
    var state = new JokeState(null);
    state.receive("Why? Because.");
    Test.assertEqual(state.confirm(true), false);
    Test.assertEqual(state.revealed, true);
    Test.assertEqual(state.confirm(true), true);
    Test.assertEqual(state.confirm(true), false);
    state.receive(null);
    Test.assertEqual(state.confirm(true), true);
    state.receive("Next joke.");
    Test.assertEqual(state.revealed, false);
    return true;
}

(:test)
class TestFont {
    function initialize() {}
    function measure(text as String) as Number {
        return text.length();
    }
}
