# Dad Jokes for Instinct 3 Solar

A Monkey C Connect IQ **watch app** that gets random English dad jokes from [icanhazdadjoke.com](https://icanhazdadjoke.com/api). Works toward the **Instinct 3 Solar 45 mm and 50 mm** target; Garmin uses the SDK identifier `instinct3solar45mm` for both. This project does not target Instinct 3 AMOLED.

## How it works

- Downloads a joke when no saved joke exists and whenever **START** advances past the punchline.
- The watch needs a paired phone with **Garmin Connect running/allowed in the background** and an internet connection. Solar charging does not provide internet connectivity.
- Shows the smug-grin sticker ([`resources/drawables/smile.png`](resources/drawables/smile.png)) in the Instinct's upper-right subscreen circle, but only once **START** reveals the punchline. The source artwork is reduced to 54px and the panel's 1-bit black/white palette at build time.
- Wraps each text row to the display contour and around the subscreen circle. Use **UP/DOWN** to scroll pages.
- **START** progresses through setup → punchline → next joke.
- Revealing a punchline plays a short two-note "ta-da" beep (when watch tones are supported and enabled).
- Saves the last good joke across app sessions. On request failure, the saved joke remains visible. With no saved joke, a connection/retry message appears.
- Requires no API key or companion app of your own. Requests send no location, activity, or health data. The joke service receives ordinary HTTP request metadata.

The provider controls joke content and availability. Malformed, empty, failed, and oversized responses are rejected; the cached joke is preserved. There is no offline joke collection bundled with the app.

## Build

1. Install Java 17 and the [Garmin Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/).
2. Sign in to the SDK Manager and install a current SDK plus **Instinct 3 Solar 45mm / 50mm** and its fonts. Device profiles require Garmin sign-in; downloading only the SDK is insufficient.
3. Install Garmin's **Monkey C** VS Code extension (recommended by this workspace).
4. Set the SDK and signing-key paths as needed:

   ```sh
   export CONNECTIQ_SDK="/absolute/path/to/connectiq-sdk"
   export CIQ_DEVELOPER_KEY="/absolute/path/to/developer_key.der"
   export JAVA_HOME="/absolute/path/to/jdk/Contents/Home"
   ```

   This workspace already has a local SDK, Java 17, and development signing key in the ignored `.tools/` directory. The script uses them automatically. Those are local build tools, not distributable project dependencies. To create a new key on another machine:

   ```sh
   mkdir -p .tools
   openssl genrsa -out .tools/developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER \
     -in .tools/developer_key.pem -out .tools/developer_key.der -nocrypt
   ```

   Keep the key private and retain the same key for future published updates.

5. Build with the default VS Code build task or:

   ```sh
   bash scripts/ciq.sh build
   ```

   The device-specific output is `bin/DadJokes.prg`. If the compiler says `Invalid device id specified`, install the Solar device profile in SDK Manager first.

## Simulator and tests

```sh
bash scripts/ciq.sh simulator
bash scripts/ciq.sh test
bash scripts/ciq.sh run-tests
bash scripts/ciq.sh build
bash scripts/ciq.sh run
```

The [Monkey C tests](tests/JokeTests.mc) cover response validation, whitespace, oversized text, cache preservation after failure, wrapping long words, and the final page of a joke. The simulator must be running before `run` or `run-tests`.

For manual testing:

1. Open the app and confirm the setup appears without overlapping the upper-right circle.
2. Press **UP/DOWN** and confirm long text scrolls through every page.
3. Press **START** to show the punchline and hear the two-note beep, then **START** again to download the next joke without another beep.
4. Disable the simulator's phone connection, request another joke, and confirm the saved joke remains.
5. Re-enable the connection, request again, and confirm recovery.
6. Restart the app and confirm it restores the saved joke.

## Install on the watch

After a successful **device-specific** build, connect the watch by USB, copy `bin/DadJokes.prg` into the watch's `GARMIN/APPS` directory, and safely disconnect. Restart the watch if needed, then open **Dad Jokes** from the Apps list with the phone connected.

## Verification status

The implementation passes strict type checking and builds for **Instinct 3 Solar with Connect IQ SDK 9.2.0**. The simulator reports all 11 Monkey C tests passing. Garmin's `monkeydo` exits with status 1 after its `PASSED` summary on this setup.

## Source

- [Application lifecycle and persistent cache](source/DadJokesApp.mc)
- [Response validation](source/JokeResponse.mc)
- [Display and paging](source/JokeView.mc)
- [Text wrapping](source/JokeText.mc)
- [Punchline smiley bitmap](source/JokeFace.mc)
- [Cache state](source/JokeState.mc)

Garmin references: [web requests](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html) and [Instinct 3 Solar device reference](https://developer.garmin.com/connect-iq/reference-guides/devices-reference/#instinct3solar45mm).
