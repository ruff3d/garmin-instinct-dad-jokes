import Toybox.Lang;

module JokeText {
    // Pixel measurements are supplied by the view; tests use a fixed-width font.
    function wrap(text as String, width as Number,
                  measure as Method(text as String) as Number) as Array<String> {
        return wrapRows(text, [width] as Array<Number>, measure);
    }

    function wrapRows(text as String, widths as Array<Number>,
                      measure as Method(text as String) as Number) as Array<String> {
        var lines = [] as Array<String>;
        var remaining = text;
        while (remaining.length() > 0) {
            var width = widths[lines.size() % widths.size()];
            var end = 0;
            var lastSpace = -1;
            while (end < remaining.length()) {
                if (measure.invoke(remaining.substring(0, end + 1) as String) > width) { break; }
                if ((remaining.substring(end, end + 1) as String).equals(" ")) { lastSpace = end; }
                end += 1;
            }
            if (end == remaining.length()) {
                lines.add(remaining);
                break;
            }
            if (end == 0) { end = 1; }
            // If the next character is a space, the whole measured line fits.
            if (lastSpace > 0 && !(remaining.substring(end, end + 1) as String).equals(" ")) {
                end = lastSpace;
            }
            lines.add(remaining.substring(0, end) as String);
            remaining = remaining.substring(end, remaining.length()) as String;
            while (remaining.length() > 0 && (remaining.substring(0, 1) as String).equals(" ")) {
                remaining = remaining.substring(1, remaining.length()) as String;
            }
        }
        if (lines.size() == 0) { lines.add(""); }
        return lines;
    }

    // Splits a joke into setup and punchline so the punchline can stay hidden.
    // A question mark wins; otherwise the final sentence is the punchline.
    function split(text as String) as Array<String> {
        var cut = breakAfter(text, "?");
        if (cut < 0) { cut = lastSentenceBreak(text); }
        if (cut < 0) { return [text] as Array<String>; }
        var setup = (text.substring(0, cut) as String);
        var punchline = (text.substring(cut, text.length()) as String);
        while (punchline.length() > 0 && (punchline.substring(0, 1) as String).equals(" ")) {
            punchline = punchline.substring(1, punchline.length()) as String;
        }
        if (punchline.length() == 0) { return [text] as Array<String>; }
        return [setup, punchline] as Array<String>;
    }

    function breakAfter(text as String, mark as String) as Number {
        for (var i = 0; i < text.length() - 1; i += 1) {
            if ((text.substring(i, i + 1) as String).equals(mark)) { return i + 1; }
        }
        return -1;
    }

    function lastSentenceBreak(text as String) as Number {
        for (var i = text.length() - 2; i > 0; i -= 1) {
            var ch = text.substring(i, i + 1) as String;
            if ((ch.equals(".") || ch.equals("!")) &&
                (text.substring(i + 1, i + 2) as String).equals(" ")) {
                return i + 1;
            }
        }
        return -1;
    }

    function pageCount(lineCount as Number, linesPerPage as Number) as Number {
        return ((lineCount + linesPerPage - 1) / linesPerPage).toNumber();
    }
}
