# Forth Interpreter

## How to run

1. Make sure that the Ruby is installed
2. Open a terminal at the main directory path
3. Run the following command to start the interpreter: `ruby forth.rb`
4. Use the following command: "exit/EXIT" or "quit/QUIT" or Ctrl+C to quit the interpreter

## Features

This interpreter has implemented all the features from part1 to part3. 

It accepts simple words command line arguments, can do definitions and control statements, and supports variables and constants.

## Some Edge Cases Explainations

1. String Printing

When using the interpreter to print some strings, you should leave a space or a new line at the end of the string definition, or the ok status will be just at the end of the string. For example, `48 DUP ." The top of the stack is " . CR ." which looks like '" DUP EMIT ." ' in ASCII"` would print

```
The top of the stack is 48
which looks like '0' in ASCIIok
```

with ok at the end of the string ASCII. A space or a new line is recommended. 

2. Error message and Ok status

When there's an error message, the ok status will not be printed.

3. Error checking in complicated definitions and control statements

When the Begin, Do, If statements are executed, the check stack operation will be excuted. It will return error if there's no element in the stack or less elements than requirements. 

4. Multiple lines support

The interpreter supports multiple lines of input. It will be valid for `:;` `DO LOOP` `BEGIN UNTIL` `IF ELSE THEN` on different lines. 

5. Upcase and lower case situation

The interpreter will ignore the upper case and lower case situations. For example, the interpreter will accept even the word case is strange, "1 dUMp iF 1 ElSE thEN". 

6. Exit the interpreter

When you do ctrl+c or exit or quit, the interpreter will print "Exit Forth Interpreter" and close it.


## Error Handling

The interpreter will automatically output some error messages when some errors happen, which will be displayed in the console. 

1. "error: not enough elements in stack"

2. "error: empty stack"

When the interpreter encounters a pop command, but there are no elements in the stack, it will show "error: empty stack", but when there are more elements needed in the pop command, for example, SWAP command would use 2 elements pops from the stack, but there's only one element in that stack, it will raise the "error: not enough elements in stack" error. 

3. "error: unknown input word '\<the unknown word\>'"

When the interpreter has a unknown command argument, it will display the error message "error: unknown input word '\<the unknown word\>'". For example, the interpreter input is "fwefew" which means nothing, then the error message will show "error: unknown input word '\<fwefew\>'". 

4. "Error: Cannot read from address \<Address Number\>"

When the interpreter reads a heap address of less than 1000, it will raise an exception of "Error: Cannot read from address \<Address Number\>". For example, the interpreter reads "1 2 !" it will raise an exception of "Error: Cannot read from address 2". 

5. All other errors

The interpreter will also raise an exception if some other error is encountered. For example, `1 0 /` will print the error message: "An error occurred: divided by 0"

