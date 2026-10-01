import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class DadJokesApp extends Application.AppBase {
    private var _state as JokeState?;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var state = new JokeState(loadJokes());
        _state = state;
        if (state.current() == null && state.beginRequest()) { requestJoke(); }
        var view = new JokeView(state);
        return [view, new JokeDelegate(state, view)];
    }

    private function loadJokes() as Array<String>? {
        var stored = Application.Storage.getValue("jokes");
        if (!(stored instanceof Array)) {
            var legacy = JokeResponse.parse(200, {
                "status" => 200,
                "joke" => Application.Storage.getValue("joke")
            });
            return legacy != null ? [legacy] as Array<String> : null;
        }
        var jokes = [] as Array<String>;
        for (var i = 0; i < stored.size(); i += 1) {
            // Validate stored content too, so unexpected storage cannot break rendering.
            var joke = JokeResponse.parse(200, {"status" => 200, "joke" => stored[i]});
            if (joke != null) { jokes.add(joke); }
        }
        return jokes;
    }

    function onResponse(code as Number, data as Dictionary or String or Null) as Void {
        receiveForegroundJoke(JokeResponse.parse(code, data));
    }

    function requestJoke() as Void {
        try {
            Communications.makeWebRequest("https://icanhazdadjoke.com/", null, {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Accept" => "application/json",
                    "User-Agent" => "Instinct Dad Jokes Connect IQ watch app"
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            }, method(:onResponse));
        } catch (error) {
            receiveForegroundJoke(null);
        }
    }

    private function receiveForegroundJoke(joke as String?) as Void {
        if (_state != null) { _state.receive(joke); }
        saveJokes();
    }

    private function saveJokes() as Void {
        if (_state != null) {
            try {
                Application.Storage.setValue("jokes",
                    (_state as JokeState).jokes as Array<Application.Storage.ValueType>);
            } catch (error) {
                // A full persistent store must not prevent showing the new joke.
                System.println("Dad Jokes: could not save jokes.");
            }
        }
        WatchUi.requestUpdate();
    }

}
