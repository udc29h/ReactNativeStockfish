# @udaychauhan/react-native-stockfish

Use stockfish chess engine in your React Native application.

## Installation

```sh
npm install @udaychauhan/react-native-stockfish
```

## Usage

```js
import {
  useStockfish
} from '@udaychauhan/react-native-stockfish';

// ...

const [stockfishOutput, setStockfishOutput] = useState('');
  const {stockfishLoop, stopStockfish, sendCommandToStockfish} = useStockfish({
    onOutput: useCallback((output: string) => {
      setStockfishOutput((prev) => prev + output);
    }, []),
    onError: useCallback((error: string) => {
      setStockfishOutput((prev) => `${prev}\n###Err\n${error}\n###`);
    }, [])
  });

// ...

stockfishLoop();

// ...

sendCommandToStockfish('go movetime 1000');

// ...

stopStockfish();
```

## Testing example project

Get started with the project:

$ yarn

Run the example app on iOS:

$ yarn example ios

Run the example app on Android:

$ yarn example android

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

### Changing Stockfish source files

If you need to upgrade Stockfish source files, create a folder **stockfish** inside **cpp** folder, copy the **src** folder from the stockfish sources into the new **stockfish folder**.

In **stockfish/src/main.cpp** replace the name of function `main` with `stockfish_core`.

Also you need to make some more adaptive works :

#### Adapting streams

- copy the **cpp/fixes** folder inside the **cpp/stockfish** folder

- replace all calls to `cout << #SomeContent# << endl` by `fakeout << #SomeContent# << fakeendl` (And ajust also calls to `cout.rdbuf()` by `fakeout.rdbuf()`) **But do not replace calls to sync_cout**.
- copy folder **cpp/fixes** inside the **stockfish** folder
- add include to **../fixes/fixes.h** in all related files (and adjust the include path accordingly)
- proceed accordingly for `cin` : replace by `fakein`
- and the same for `cerr`: replace by `fakeerr`
- in **misc.h** replace

```cpp
#define sync_cout std::cout << IO_LOCK
#define sync_endl std::endl << IO_UNLOCK
```

with

```cpp
#define sync_cout fakeout << IO_LOCK
#define sync_endl fakeendl << IO_UNLOCK
```

and include **../../fixes/fixes.h**

#### Adapting NNUE

In file **CMakeLists.txt** replace the names of big and small NNUE by the ones you can find in file **cpp/stockfish/src/evaluate.h**. Also replace those values in the file **ReactNativeStockfish.podspec**, as well as in the file **android/CMakeLists.txt**.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)

## Credits

Using sources of [Stockfish 17](https://stockfishchess.org/).
