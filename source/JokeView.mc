import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class JokeView extends WatchUi.View {
    private var _state as JokeState;
    private var _text as String = "";
    private var _lines as Array<String> = [];
    private var _layoutWidth as Number = 0;
    private var _layoutHeight as Number = 0;
    private var _rowLefts as Array<Number> = [];
    private var _rows as Number = 1;
    private var _offset as Number = 0;
    private var _wrapOffset as Number = -1;
    private var _dc as Graphics.Dc?;

    function initialize(state as JokeState) {
        View.initialize();
        _state = state;
    }

    // ponytail: one line per press. Smooth pixel animation would need an
    // off-screen buffer the Instinct's graphics budget does not justify.
    function scroll(delta as Number) as Void {
        _offset += delta;
        var max = _lines.size() - _rows;
        if (_offset > max) { _offset = max; }
        if (_offset < 0) { _offset = 0; }
    }

    function resetScroll() as Void {
        _offset = 0;
    }

    function measure(text as String) as Number {
        return (_dc as Graphics.Dc).getTextWidthInPixels(text, Graphics.FONT_MEDIUM);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var left = 8;
        var top = 4;
        var bottom = 6;

        var sub = WatchUi has :getSubscreen ? WatchUi.getSubscreen() : null;
        var hasSub = sub != null && sub.x != null && sub.y != null;
        var circleX = 0;
        var circleY = 0;
        var circleRadius = 0;
        var subTop = 0;
        var subBottom = 0;
        if (sub != null && sub.x != null && sub.y != null) {
            var subX = sub.x as Number;
            var subY = sub.y as Number;
            circleX = subX + sub.width / 2;
            circleY = subY + sub.height / 2;
            circleRadius = (sub.width < sub.height ? sub.width : sub.height) / 2;
            subTop = subY;
            subBottom = subY + sub.height;
            // The sticker grin is the punchline payoff, so it only shows then.
            if (_state.revealed) {
                JokeFace.draw(dc, circleX, circleY, circleRadius - 4);
            }
        }

        var fontHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var available = h - top - bottom;
        var rows = (available / fontHeight).toNumber();
        if (rows < 1) { return; }
        var rowWidths = [] as Array<Number>;
        _rowLefts = [] as Array<Number>;
        for (var row = 0; row < rows; row += 1) {
            var lineTop = top + row * fontHeight;
            var centerY = lineTop + fontHeight / 2;
            var inset = contourInset(centerY, h);
            var lineLeft = inset > left ? inset : left;
            var lineRight = w - inset;
            if (hasSub && lineTop < subBottom && lineTop + fontHeight > subTop) {
                var nearestY = circleY;
                if (nearestY < lineTop) {
                    nearestY = lineTop;
                } else if (nearestY > lineTop + fontHeight) {
                    nearestY = lineTop + fontHeight;
                }
                var dy = nearestY - circleY;
                if (dy < 0) { dy = -dy; }
                var square = circleRadius * circleRadius - dy * dy;
                if (square >= 0) {
                    var circleLeft = circleX - Math.sqrt(square).toNumber() - 3;
                    if (circleLeft < lineRight) { lineRight = circleLeft; }
                }
            }
            _rowLefts.add(lineLeft);
            rowWidths.add(lineRight - lineLeft);
        }

        var joke = _state.current();
        var text = "";
        if (joke == null) {
            text = _state.offline
                ? "Connect phone. Press START to retry."
                : "Waiting for a joke. Keep phone connected.";
        } else {
            var parts = JokeText.split(joke);
            text = parts.size() == 2
                ? (_state.revealed ? parts[1] : parts[0])
                : joke;
        }

        if (!text.equals(_text) || w != _layoutWidth || h != _layoutHeight) {
            _text = text;
            _layoutWidth = w;
            _layoutHeight = h;
            _offset = 0;
            _wrapOffset = -1;
        }

        _rows = rows;
        if (_wrapOffset != _offset) {
            _dc = dc;
            _lines = JokeText.wrapRows(text, JokeText.rotateWidths(rowWidths, _offset),
                                       method(:measure));
            _dc = null;
            _wrapOffset = _offset;
        }
        var max = _lines.size() - rows;
        if (_offset > max) { _offset = max; }
        if (_offset < 0) { _offset = 0; }
        for (var row = 0; row < rows && _offset + row < _lines.size(); row += 1) {
            dc.drawText(_rowLefts[row], top + row * fontHeight, Graphics.FONT_MEDIUM,
                        _lines[_offset + row], Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function contourInset(y as Number, height as Number) as Number {
        var corner = 40;
        if (y < corner) { return 6 + corner - y; }
        if (height - y < corner) { return 6 + corner - (height - y); }
        return 6;
    }
}

class JokeDelegate extends WatchUi.BehaviorDelegate {
    private var _state as JokeState;
    private var _view as JokeView;

    function initialize(state as JokeState, view as JokeView) {
        BehaviorDelegate.initialize();
        _state = state;
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.scroll(1);
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.scroll(-1);
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var joke = _state.current();
        var hasPunchline = joke != null && JokeText.split(joke).size() == 2;
        var wasRevealed = _state.revealed;
        if (_state.confirm(hasPunchline)) {
            (Application.getApp() as DadJokesApp).requestJoke();
        } else if (!wasRevealed && _state.revealed
                   && Attention has :playTone && Attention has :ToneProfile) {
            // ponytail: short native tones; volume follows the watch setting.
            Attention.playTone({:toneProfile => [
                new Attention.ToneProfile(1800, 85),
                new Attention.ToneProfile(2400, 145),
                new Attention.ToneProfile(2100, 85),
                new Attention.ToneProfile(1800, 175)
            ]});
        }
        _view.resetScroll();
        WatchUi.requestUpdate();
        return true;
    }
}
