import Toybox.Lang;

class JokeState {
    // ponytail: buttons no longer browse history, so retain only the current joke.
    const MAX = 1;

    var jokes as Array<String>;
    var offline as Boolean = false;
    var revealed as Boolean = false;
    var waiting as Boolean = false;

    function initialize(saved as Array<String>?) {
        jokes = saved != null ? saved : [] as Array<String>;
        if (jokes.size() > MAX) { jokes = jokes.slice(jokes.size() - MAX, null); }
    }

    function current() as String? {
        return jokes.size() > 0 ? jokes[jokes.size() - 1] : null;
    }

    function receive(value as String?) as Void {
        waiting = false;
        offline = value == null;
        if (value == null) { return; }
        jokes.add(value);
        if (jokes.size() > MAX) { jokes = jokes.slice(jokes.size() - MAX, null); }
        revealed = false;
    }

    // Returns true when Select should fetch the next joke.
    function confirm(hasPunchline as Boolean) as Boolean {
        if (hasPunchline && !revealed) {
            revealed = true;
            return false;
        }
        return beginRequest();
    }

    function beginRequest() as Boolean {
        if (waiting) { return false; }
        waiting = true;
        return true;
    }
}
