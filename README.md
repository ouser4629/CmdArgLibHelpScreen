<!-- 
//  Copyright (c) 2025-2026 Psummerland2 LLC.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.
-->

## CmdArgLibHelpScreen

CmdArgLibHelpScreen is part of the [Command Argument Library](https://github.com/psummerland2/cmd-arg-lib.git).

It provides a "meta-flag" constructor that can be used to generate help screens.

---

## Usage

Declare an array
of [`ShowElements`](https://github.com/psummerland2/cmd-arg-lib/blob/main/REFERENCE.md#show-elements) that
defines your help screen:

```
static let helpLayout: [ShowElement] = [ ... ]
```

If you are using the library's macro-based API, add the following parameter to 
the annotated command function:

```
h__help: MetaFlag = MetaFlag(helpElements: helpLayout)
```

If you are using the library's struct-based API, add the following variable to the conforming struct:

```
var h__help: MetaFlag = MetaFlag(helpElements: helpLayout)
```

If "-h" or "--help" is encountered in a command argument list, the help screen defined by `helpLayout` will be 
generated and written to standard output.

---

## Sample

<details>
<summary>Code</summary>

```swift
import CmdArgLibCore
import CmdArgLibMacros
import CmdArgLibHelpScreen

@main
struct Main {
    typealias Phrase = String

    @MainFunctionMacro(shadowGroups: ["u l"])
    static public func printM1(
        h__help: MetaFlag = MetaFlag(helpElements: helpLayout),
        l: Flag,
        u: Flag,
        count: Int = 1,
        _ phrase: Phrase) throws
    { ... }

    static let helpLayout: [ShowElement] = [
        .text("DESCRIPTION\n", "Print a $D{phrase} multiple times."),
        .synopsis("\nUSAGE\n"),
        .text("\nPARAMETERS"),
        .parameter("h__help", "Show help information"),
        .parameter("l", "Lowercase the output"),
        .parameter("u", "Uppercase the output"),
        .parameter("count", "The number of times to print the $D{phrase}"),
        .parameter("phrase", "The $D{phrase} to print"),
        .text("\nNOTE\n", "The $S{l} and $S{u} flags shadow each other. The last one specified takes precedence."),
    ]
}

"$S{l}" and "$S{u}" are show macros that are expanded by the help screen generator.
For example, "$S{u}" will be replaced by a formatted rendering of the shortest 
argument label associated with the parameter named `u`, "-u".

```

</details>

<details>
<summary>Help Screen</summary>

```
> print-m1 --help
DESCRIPTION
  Print a phrase multiple times.

USAGE
  print-m1 [-hlu] [--count <int>] <phrase>

PARAMETERS
  -h/--help             Show help information.
  -l                    Lowercase the output.
  -u                    Uppercase the output.
  --count <int>         The number of times to print the phrase (default: 1).
  <phrase>              The phrase to print.

NOTE
  The -l and -u flags shadow each other. The last one specified takes precedence.
```

</details>

---

## Examples

[Command Argument Library](https://github.com/psummerland2/cmd-arg-lib.git) has extensive examples
that show how to use `CmdArgLibHelpScreen`.

---

## Project Status

This software is licensed under the [Mozilla Public License, v. 2.0 "MPL-2.0"](https://mozilla.org/MPL/2.0).

It is currently in beta (version 0.5.0), and has only been tested for macOS.
