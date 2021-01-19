Title:  Fenced Code Blocks

Tags:   code, extension, fence

Status: 9 - Tested

Seq:    15.0

Code: 

```
code
```

Body: 

As an extension to the original Markdown spec from John Gruber, fenced code blocks are supported. 

This is an extension documented in the [Markdown Guide](https://www.markdownguide.org/extended-syntax/), but the Notenik parser is actually coded to conform to the [Python Markdown spec](https://python-markdown.github.io/extensions/fenced_code_blocks/).

A code fence will consist of a line consisting of only a repeated number of special characters. 

The character used may be either a backtick (\`) or a tilde (`~`). 

The character must be repeated three or more times. 

The ending code fence must contain the same number of repetitions as the line that started the code block, using the same special character. 

