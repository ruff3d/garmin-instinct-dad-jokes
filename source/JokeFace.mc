import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// ponytail: the supplied sticker, reduced to the panel's 1bpp palette at 54px
// build time, so drawing it is a single blit with no runtime scaling.
module JokeFace {
    var cached as WatchUi.BitmapResource or Null = null;

    // The smug grin is the punchline payoff, centred on the subscreen circle.
    function draw(dc as Graphics.Dc, cx as Number, cy as Number,
                  radius as Number) as Void {
        if (radius < 12) { return; }

        var face = cached;
        if (face == null) {
            face = WatchUi.loadResource(Rez.Drawables.SmileFace)
                as WatchUi.BitmapResource;
            cached = face;
        }
        dc.drawBitmap(cx - face.getWidth() / 2, cy - face.getHeight() / 2, face);
    }
}
