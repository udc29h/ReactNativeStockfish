import {
  Text,
  View,
  TextInput,
  Button,
  ScrollView,
  StyleSheet,
} from 'react-native';
import { useEffect, useState, useCallback } from 'react';
import { useStockfish } from '@udaychauhan/react-native-stockfish';

export default function App() {
  const [command, setCommand] = useState('');
  const [stockfishOutput, setStockfishOutput] = useState('');

  const { stockfishLoop, stopStockfish, sendCommandToStockfish } = useStockfish(
    {
      onOutput: useCallback((output: string) => {
        setStockfishOutput((prev) => {
          return prev + output;
        });
      }, []),
      onError: useCallback((error: string) => {
        setStockfishOutput((prev) => {
          return `${prev}\n###Err\n${error}\n###`;
        });
      }, []),
    }
  );

  useEffect(() => {
    /////TEMPORARY
    console.log('start effect');
    /////
    const sendUciCommand = () => sendCommandToStockfish('uci');
    stockfishLoop();
    setTimeout(sendUciCommand, 800);

    return () => {
      stopStockfish();
      /////TEMPORARY
      console.log('stop effect');
      /////
    };
  }, [stockfishLoop, stopStockfish, sendCommandToStockfish]);

  return (
    <View style={styles.container}>
      <View style={styles.inputContainer}>
        <Text>Command: </Text>
        <TextInput
          style={styles.inputControl}
          placeholder="Your command"
          value={command}
          onChangeText={setCommand}
        />
        <Button
          title="Send"
          onPress={() => {
            setStockfishOutput('');
            sendCommandToStockfish(`${command.toLowerCase()}\n`);
            setCommand('');
          }}
        />
      </View>
      <ScrollView>
        <Text>{stockfishOutput}</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'flex-start',
    marginTop: 100,
  },
  inputContainer: {
    flexDirection: 'row',
    alignSelf: 'flex-start',
    alignItems: 'center',
    justifyContent: 'flex-start',
  },
  inputControl: {
    flex: 1,
    minWidth: 200,
    padding: 5,
  },
});
