#  Markdown Parser

The Markdown parser provided with Notenik attempts to satisfy all of the requirements laid out on the [Markdown syntax page][syntax] found on the [Daring Fireball site][df]. 

[syntax]: https://daringfireball.net/projects/markdown/syntax
[df]: https://daringfireball.net/

## Parsing Strategy

The class 'MkdownParser' is the overall parser that is called in order to convert Markdown to HTML. 

The first phase of the parser breaks the input text down into lines, examining the beginning and end of each line, and identifying the type of each line. 

* The class 'MkdownLinePhase' is used to keep track of where the parser is within each line, as it is being examined. 

* The class 'MkdownLineType' defines the various types of lines. 

* The class 'MkdownLine' stores each line, including its type, and other metadata about the line. 

The resulting lines are stored in an array, which is passed on to the next phase of the parser's processing. 
