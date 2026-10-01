import Toybox.Lang;

module JokeResponse {
    const MAX_LENGTH = 512;

    function parse(code as Number, data as Object?) as String? {
        if (code != 200 || !(data instanceof Dictionary)) { return null; }
        if (data["status"] != 200) { return null; }
        var joke = data["joke"];
        if (!(joke instanceof String) || joke.length() > MAX_LENGTH) { return null; }
        var result = "";
        var space = false;
        for (var i = 0; i < joke.length(); i += 1) {
            var ch = joke.substring(i, i + 1) as String;
            if (ch.equals(" ") || ch.equals("\n") || ch.equals("\r") || ch.equals("\t")) {
                space = result.length() > 0;
            } else {
                if (space) { result += " "; }
                result += ch;
                space = false;
            }
        }
        return result.length() > 0 ? result : null;
    }
}
