# Nim Media Manager

A practical exercise for trying out Nim: a multimedia manager application.

Let's start with a TUI and see if we want to work on a GUI version afterwards.

The first step is to install Nim. I'm going to be working on macOS.

## Installing Nim on macOS

Nim provides at least two options of installation on macOS: `choosenim` and a
Homebrew option. Eventually we might want to use `choosenim` in case we decide
to support this project for the long term and we need to carry it over from one
compiler version to the next.

But for now we just want the latest Nim compiler as of the time of writing.
Let's use the Homebrew option.

If you do not have Homebrew installed on your Mac, please follow the steps at
https://brew.sh/. At the time of writing that amounts to running this command in
the terminal:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

To install Nim using Homebrew, run `brew install nim`. Once this command exits,
ensure Nim is now installed by running `nim -v`. My version being printed at the
time of writing is:

```
Nim Compiler Version 1.4.0 [MacOSX: amd64]
Compiled at 2020-10-17
Copyright (c) 2006-2020 by Andreas Rumpf

active boot switches: -d:release -d:nimUseLinenoise
```

You might also want to check that Nim is correctly added to `$PATH` by closing
and reopening the terminal and rerunning the `nim -v` command to see if it still
works. You can also just run `zsh` (the current macOS shell on Catalina) to
restart the terminal session.

Our next step with the compiler now at hand will be to run Hello World. If we
can get that to run, we can get anything to run.

## Putting together a Hello World program

Let's create `hello-world.nim` and try to write a program to write to the
standard output:

`hello-world.nim`
```nim
echo "Hello, world!"
```

To compile and run the program, let's run `nim compile --run hello-world.nim`.

```
Error: invalid module name: hello-world
```

Hmmm, what could this highly descriptive error message possibly mean? We're not
using any modules, this is just a simple Hello World app. And already the
modules we are not using have invalid names?

Turns out, Nim has the concept of implicit module names where the module name is
derived from the file name (at least it appears to be the case here) and since a
valid Nim identifier can not include a dash, the compiler craps out on us.

Let's push past the fact that the error message could use some work and rename
the file to use an underscore instead:

`hello_world.nim`
```nim
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/nim.cfg' [Conf]
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/config.nims' [Conf]
...
echo "Hello, world!"
```

While we're at it, let's also become pros at the Nim CLI and use the shortened
names of the `compile` command and `--run` switch: `c` and `-r`! Also, let's not
type the extension either - it will be assumed to be the default `.nim` so we do
not have to bother!

`nim c -r hello_world`

```
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/nim.cfg' [Conf]
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/config.nims' [Conf]
....
Hint:  [Link]
Hint: 22157 lines; 0.344s; 25.527MiB peakmem; Debug build; proj: /Users/tomashubelbauer/Desktop/nim-media-manager/hello_world; out: /Users/tomashubelbauer/Desktop/nim-media-manager/hello_world [SuccessX]
Hint: /Users/tomashubelbauer/Desktop/nim-media-manager/hello_world  [Exec]
Hello, world
```

That looks much better! Now let's think about the next step. To manage our media
library, we need a way to add some media in it. Without any added, we won't have
any to manage.

## Accepting `stdin` input

Let's ditch `hello_world.nim` and the newly created `hello_world` binary Nim
compiled for us.

We'll start a new file named `media_manager.nim` and in it, we'll try to accept
some user input and present it back to the user. This way we can be sure we know
how to receive input and present it while it is in memory.

`media_manager.nim`
```nim
echo "Add Media"
echo "Title:"
var title: string = readLine(stdin)
echo "Added '", title, "'"
```

Sweet, this works! However the final `echo` line is not the pinnacle of
readability. Let's use a formatted string, which in Nim should use this syntax:

```nim
fmt"static{dynamic}static"
```

Any expression within `{` and `}` will be interpolated into the resulting value.
To be able to use this, we need to extend a Nim module which comes with the Nim
standard library (or whatever the set of modules which come with the compiler is
called in Nim): `import strformat`.

```nim
import strformat

echo "Add Media"
echo "Title:"
var title: string = readLine(stdin)
echo fmt"Added '{title}'"
```

Looking even better. One last thing that would be interesting to find out is how
would we escape the quotes if we wanted to use double quotes inside the string
literal. Right now we're using single quotes but I've picked them only to avoid
conflict with the string literal syntax tokens - the double quotes. Let's not
settle for less quotes if we can have more with this one weird trick. So what's
the weird trick? Let's think back to our Visual Basic days. Just double the
double quote up!

```nim
echo fmt"Added ""{title}"""
```

Notably, `\"` is not a correct way to escape a double quote in a string in Nim.
I'm not sure exactly what the deal is with Nim, but `\n` does appear to be the
right way to represent a newline in a string literal, so I'm fairly sure that
the trick is that there's just a very small set of backslash literals that are
special-cased in strings. Probably just `\r`, `\n`, `\t` and maybe some others.

We don't need newlines here though (`echo` terminates the printed string with
one for us automatically) so we need to use the alternative way of escaping -
using the opening and closing double quote.

Now that we can accept standard input buffer input, keep it in memory and print
it from memory, the next logical step is to figure out how to write to a file as
well as recover from a file so that our media is longer-lived that the current
invocation of our Media Manager program!

## Writing to a file

There's a nice example of writing to a file in Nim at
https://nim-by-example.github.io/files/ so let's just cop that real quick. Let's
append the following after our last `echo` call:

```nim
writeFile("data.dat", title)
```

Somehow, amazingly, to write to a file, one needs not import any modules, even
though for something as basic as string interpolation is, we already had to
reach for a standard library module. :-)

Be that as it may though, our next step is to read the file and print its
content so that we know what media we already manage and we don't end up adding
something twice by mistake.

## Reading from a file

The same site also lists an example of reading from a file. The game plan here
is to pretty much just read the entire file upfront, print it so that we know
what we already track, ask for new media to manage and once provided, append
this new item to the existing ones and persist the whole combined bunch so that
the next time the program runs, we print the entire collection inclusive of this
new item.

First, we read:

```nim
import strformat

let media = readFile("data.dat")
echo "Existing Media:"
echo media
echo "Add Media"
echo "Title:"
var title: string = readLine(stdin)
echo fmt"Added ""{title}"""
writeFile("data.dat", title)
```

But this will just keep replacing the sole item being tracked each time we "Add"
new media. That's no good. Let's fix that.

```nim
import strformat

let media = readFile("data.dat")
echo "Existing Media:"
echo media
echo "Add Media"
echo "Title:"
var title: string = readLine(stdin)
echo fmt"Added ""{title}"""
writeFile("data.dat", fmt"{media}\n{title}")
```

This is better! The new item is appended after the existing ones in the file as
it is being persisted after the addition. We even got to use the fancy `\n` VIP
backslash string literal token.

Note that unlike `echo` which will accept seemingly any number of arguments
separated by a comma, `writeFile` has just two arguments - the file name and the
file content string, so we can't use `writeFile("data.dat", media, "\n", title)`
here. Not that it would be preferred even if it worked, because it looks bad
anyway.

So we got somewhere, but now if we re-run we can see yet another issue! The text
of the "database" file, when printed back with more items than one, seems to
contain literal `\n`, not newlines! In other words:

What we have:

```
first\nsecond
```

What we want:

```
first
second
```

Are my eyes deceiving me or did the precious `\n` cheat us? Is it really not
that special, can it be, that it does not in fact get interpreted as a newline?

I shudder at the idea, but we've no time to waste, so let's apply the Scientific
Method and gather some data. Now, it would be really cool if we could do that
outside of our current codebase, because we don't want to irrevocably mess it up
and we're going to ignore the fact that we could use Git to avoid this because
otherwise this whole build-up would not lead squarely to inquiring about whether
Nim has a REPL and I won't have that.

So, does the Nim compiler support REPL or does it at the very least has a
command for evaluation of a stringular expression as provided in the CLI or the
stdin?

Looks like the answer is no! The compiler does have an `e` command, but is seems
to be meant for running NimScript, which we don't know what that is yet and REPL
is provided by third-party integration, not out of the box with Nim:

https://github.com/inim-repl/INim

The documentation does make a mention of interactive mode which is a REPL:
https://nim-lang.org/0.13.0/nimc.html#nim-interactive-mode

But! The command `i` straight up does not work for me:

```
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/nim.cfg' [Conf]
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/config.nims' [Conf]
Error: invalid command: i
```

Perhaps the macOS version of the Nim compiler is not built with the GNU readline
library built-in and so `nim i` is not available on macOS? Let's ask in the Nim
GitHub repository: https://github.com/nim-lang/Nim/issues/15615

We'll table that for now, clearly there's no REPL for us without switching to
Linux or using a third-party tool for which it is a little too early in the
~~morning~~ experimentation process methinks.

Let's create a new Nim file for out experiments instead, a poor man's REPL if
you wish. Now what were we going to test anyway? Oh, right, the actual status of
the `\n` token in a string literal.

`repl.nim`
```nim
echo "first\nsecond"
```

To run, we need to use `nim c -r repl` now and we should also add `repl` to our
`.gitignore`.

Bummer, this works as expected! `\n` is at least somewhat special. So why does
it not work? Is it because we're using it in a context of a formatter string or
because we're outputting the string to a file? Let's continue testing:

```nim
import strformat

echo fmt"first\nsecond"
```

Aha!!! So in a string literal with `fmt` applied, `\n` is no longer special!

I googled around and as per https://scripter.co/notes/nim-fmt/ it looks like we
can just replace `fmt` with `&` and everything will automagically work? We still
need to import `strformat` and the `{}` string substitutions still work!

```nim
import strformat

let third = "third"
echo &"first\nsecond\n{test}"
```

Let's not dig any deeper into why that is the case as it looks like a good
rabbit hole to get lost in. I'm sure this will come up again at a more
opportunate time for a tangent. For now, we have a file to save to, let's fix:

```nim
writeFile("data.dat", &"{media}\n{title}")
```

Run with our trusty `nim c -r media_manager` and let's see what the content of
the writ file looks like now.

Right! The new item is on its own line. But the first two items are still joined
on a single line by the literal `\n`. What do? Is this the dreaded part where we
code in a data migration in order to stay compatible with existing users of the
app and their broken data files? Is this our first brush with bug-compatibility?
Ha! What users? We're the only user, let's nuke `data.dat` off the face this
SSD.

`rm data.dat`

That showed it. Now let's run again and surely we won't see any bad data
anymore. `nim c -r media_manager` aaaand:

```
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/nim.cfg' [Conf]
Hint: used config file '/usr/local/Cellar/nim/1.4.0/nim/config/config.nims' [Conf]
Hint: 7732 lines; 0.063s; 11.48MiB peakmem; Debug build; proj: /Users/tomashubelbauer/Desktop/nim-media-manager/media_manager; out: /Users/tomashubelbauer/Desktop/nim-media-manager/media_manager [SuccessX]
Hint: /Users/tomashubelbauer/Desktop/nim-media-manager/media_manager  [Exec]
/Users/tomashubelbauer/Desktop/nim-media-manager/media_manager.nim(3) media_manager
/usr/local/Cellar/nim/1.4.0/nim/lib/system/io.nim(842) readFile
Error: unhandled exception: cannot open: data.dat [IOError]
Error: execution of an external program failed: '/Users/tomashubelbauer/Desktop/nim-media-manager/media_manager '
```

Well crap! This sucks and I'm not even talking about the stupid error message
this time! (Seriously, execution of an external program failed? Keep that to
yourself Nim compiler, that's not what our code is doing, our code is failing
due to an I/O error you've printed above. No need to confuse!)

Right, all that adding and we forgot to handle the most basic use-case - having
no data to begin with. Now, the Nim tutorial at
https://nim-lang.org/docs/tut2.html#exceptions says not to worry, file opens
resulting into an error due to a file's non-existence should not throw! So we
don't even have to worry about exceptions for now, great! Except they totally
do throw and we do have to worry the hell out of exceptions. :-(

Let's take a quick note of this…
https://github.com/nim-lang/Nim/issues/15616

It's REPL time to check how we could handle the exception being raised as the
file fails to open because it does not exist. Again remember to use
`nim c -r repl` since we're playgrounding here only.

```nim
try:
  echo readFile("data.dat")
except IOError:
  echo "no file"
```

That's more like it, no more crash. Let's put the theory to practice in our
actual program.

Looks like we can't shake that `except` branch even if we don't want to do
anything in it, which is a pity. We'll solve that by preparing a variable for
the file content and not initializing and initializing either to the result of
the file read or to an empty string based on the exception being raised or not.

```nim
import strformat

var media: string
try:
  media = readFile("data.dat")
except IOError:
  media = ""

echo "Existing Media:"
echo media
echo "Add Media"
echo "Title:"
var title: string = readLine(stdin)
echo fmt"Added ""{title}"""
writeFile("data.dat", &"{media}\n{title}")
```

This is good. We're good. The file missing does not crash the program anymore.
We do have some visual blemishes though. We don't want to print the whole
"Existing Media" section just to have it be empty. Let's be user friendly here.
Let's only print it if there are some existing media actually, and let's print
a nice and friendly message in case there aren't any. We'll take this chance to
assume this is the user's first-time visit to the app and treat it as a tutorial
opportunity. It will show until the user adds any media.

```nim
import strformat

try:
  let media = readFile("data.dat")
  echo "Existing Media:"
  echo media
  echo "Add Media"
except IOError:
  echo "No media! Please add media to start:"

echo "Title:"
var title: string = readLine(stdin)
echo fmt"Added ""{title}"""
writeFile("data.dat", &"{media}\n{title}")
```

This _should_ be cool UX-wise, the flow is nice and all, but we have a problem
still. When we go to persist the data at the end of the program, we need to get
the existing media so we still need a top-level reference to it. I thought we
might get away with turning `media` into a scoped variable, but it's time to
hoist it back up.

What's more though, if we do not have any media, and we initialize `media` to an
empty string, it's already clear from the interpolated string at the end of the
code that the first title will be added as a second item, preceeded by an empty
item resulting from the `{media}\n{title}` concatenation. In this case it works
out to be `\n{title}` as `media` is going to be an empty string.

I think it will be better to pro-actively write the newline at the end of the
file when we're saving any item. Then we can drop `\n` from the save call as it
will already be provided at the end of `media` as previously read if it does
have any items. And if not, it will still be empty and the first item added will
truly be added as a first item in the file.

It will also make the data file a bit more "proper" as it will now have a real
EOF. Overall it just feels like a righter thing to do. Let's code away…

```nim
import strformat

var media: string
try:
  media = readFile("data.dat")
  echo "Existing Media:"
  echo media
  echo "Add Media"
except IOError:
  echo "No media! Please add media to start:"

echo "Title:"
let title: string = readLine(stdin)
echo fmt"Added ""{title}"""
writeFile("data.dat", media & title & "\n")
```

Running with no `data.dat` file, we get the cool tutorial-type message and are
immediately prompted to add a title:

```
No media! Please add media to start:
Title:
```

Running with existing `dara.dat`, we sort of abuse the EOF we introduced for UI
needs, too - `echo`ing the contents of `data.dat` we also introduce an empty
line between the "Existing Media" and "Add Media" sections, which ends up
working really well UI-wise, so we can call this a serendipitous occurence and
move on. :-)

Of course one thing we need to mention here is that there is an edge case -
what if the file does exist, but is empty? In that case, "Existing Media" would
be printed, but empty. And there is even a way to create such broken file using
our very program, so we can't blame it on the user or their other software
interfering with our data file: by entering no media title and submitting
straight away - try it!

After deleting `data.dat`:

```
No media! Please add media to start:
Title:

Added ""
```

Restarting…

```
Existing Media:


Add Media
Title:
```

This is no good! We could probably get away with claiming it's too much to check
the data file for modifications by other programs rendering it malformated for
our use (that's what most software today seems to do anyway - fuzz a program
some time to see), but our own program producing a file that later bamboozles
the hell out of it? That's too much even for the software development industry.

Let's try and get it right. From my point of view, we have two choices - we can
validate the input and continue asking the user for a valid name before we add
the title, or we can treat the empty title as an indication of wanting to exit
the addition form and get away from the user's way.

I'll go ahead and do the latter here. Don't worry, I'm not avoiding loops and
this is not a cop out, I'll need to add a loop later anyway to make sure the
user can keep adding multiple titles one by one. I genuinely think this is a
better default here as opposed to having the user learn Ctrl+C to exit out of
the new title form themselves or even worse, having a special-case command-name
title which is treated as an indication of not wanting to add any titles, just
wanting to exit the form. Sure, we sort of do that by special-casing an empty
string to be this magic command to exit instead of commit the new title, but if
we are going to special-case something, shouldn't it be at least something truly
special, not just some regular old string like `none`, `exit` or `cancel` which
can be a completely valid title name? Or something unique, yeah, like `$$exit`
but so ugly it leaves the user feeling like they are the computer and the
computer is the user?

So, with that justification in mind, let's special case an empty title name to
be an indication to Media Manager to quit after having printed the existing
titles (regardless of if there are actually any).

```nim
import strformat

var media: string
try:
  media = readFile("data.dat")
  echo "Existing Media:"
  echo media
  echo "Add Media"
except IOError:
  echo "No media! Please add media to start:"

echo "Title:"
let title: string = readLine(stdin)
if (title != ""):
  echo fmt"Added ""{title}"""
  writeFile("data.dat", media & title & "\n")
```

This is starting to feel like a real program! We have some flows, finally. :-)

Also, I forgot to call this out, but did you notice the `&` operator for string
concatenation? Yeah, Nim seems to take a hint from two from Visual Basic! Maybe
not Visual Basic, it surely wasn't the first to use double quotes for escaping
and an ampersand for string concatenation, but it's still cool to see and
experience this unexpected connection.

To prove I wasn't just avoiding loops as mentioned above, let's roll with one
now to add support for adding multiple titles one by one.

### Adding titles one by one

For this, we'll pretty much just wrap the code for adding a title into a loop
and exit the loop if no title is provided, like we exit the whole program now.

Nim doesn't seem to have `do` loops, so we cannot do something like: "do add
title while the title name was non-empty and repeat". Instead, we need to flip
the script somewhat and do "while we fetch the title, if the title is empty,
quit, otherwise add and repeat".

```nim
import strformat

var media: string
try:
  media = readFile("data.dat")
  echo "Existing Media:"
  echo media
  echo "Add Media"
except IOError:
  echo "No media! Please add media to start:"

while true:
  echo "Title:"
  let title: string = readLine(stdin)
  if (title == ""):
    break

  echo fmt"Added ""{title}"""
  writeFile("data.dat", media & title & "\n")
```

This works fine, titles can be added as long as their names are provided and to
stop adding titles, just submit an empty string! Really straightforward, no
problems there from what I can see. :-)

Except… taking a look at the data file, we notice that only the last item is
being persisted? Looks like a simple loop won't be all we need after all.

This is because we read the file once at startup and when we save in the loop,
we take the file as we read it once at startup and append the current title to
it, save that. Do this a few times in a row and you'll find yourself rewriting
the data file with its content as it was at the program start with only the
trailing line varying based on the current title.

We could reload the file each time we save a new title, but that seems wasteful.
And its questionable how we would do it anyway. Do we loop the whole program?
That way we'd get the whole sequence of prompts and messages on each iteration.
That's bad UX. Or do we just replace the `media` variable with the content of
the file read anew after we've written to it? That would work, sure, but that's
a lot of I/O and unnecessary one at that just to modify something we already
have in memory and know how we modify it to produce the file only to just read
the file. Let's take the knowledge of how we produce the file and how it would
result into the `media` string having those contents if we reread it from the
file after save and instead implement those changes on the string as we have it
in memory.

But first let's get back to our old friend REPL here and test out one feature of
Nim that's really interesting: mutable, or at least appendable, strings.

In Nim, this actually works:

```nim
var text = "Hello"
text.add(" World")
echo text
# "Hello World"
```

This is cool to know because it gives us some options. Instead of producing the
final string to save as we're saving the file, we could take the title name
provided and append it to the existing title names (the `media` string) and then
just save that - the up-to-date version including the new title. Or course we
also need to append the newline here. :-)

```nim
import strformat

var media: string
try:
  media = readFile("data.dat")
  echo "Existing Media:"
  echo media
  echo "Add Media"
except IOError:
  echo "No media! Please add media to start:"

while true:
  echo "Title:"
  let title: string = readLine(stdin)
  if (title == ""):
    break

  media.add(title & "\n")
  writeFile("data.dat", media)
  echo fmt"Added ""{title}"""
```

This does nicely. Now everything works as expected - at the memory level, UI
level and now the storage level, too! I've moved the "Added {title}" messsage
after the file write, because we want it to be accurate should the file write
crash. It's better to crash straight away with an error trace as opposed to
claiming the operation worked just fine in the UI and then spewing out an error
trace.

At some point I also changed the `title` variable to a `let` binding as we're
never changing it, just a small development ergonomy thing. :-)

So now our program is a cool name appender and we can more or less track our
media collection, but we can't talk about managing our media just yet. Not until
we can delete, rename, perhaps even sort and categorize!

Let's explore these other functionalities step by step in the upcoming sections.
Starting with a decision.

## Implementing TUI navigation

So we're here, thinking about upgrading our program to be more than just a one
trick pony. (Heh, Pony - as in Pony lang - get it?)

This presents a challenge for us. We can implement two features, sure, but how
do we know which one to carry out? The user has to tell us, somehow. We need to
go deeper, or perhaps shallower is the right way to look at it actually, and
wrap this whole logic in a menu. At the very least, we need to ask, if we want
to add stuff, which we already have implemented, or do something else.

For now let's assume the next option will be to delete stuff, because, well, it
will be that. And also, let's add a real "quit" option. We can always do that by
not filling in the title, but now it starts to make more sense for that to go
back to the menu instead of straight up quitting the program, so we should still
provide the option to quit the program cleanly, somewhere better suited for it.

With our knowledge of loops, we are well equipped to start thinking about
nesting the loops. The outer loop will be used to continuously query the desired
menu option (add, delete, quit) until quit has been selected. And the addition
operation will have its own loop - fetching titles and adding them as long as
their names are being provided, and going back to the menu once they aren't.

## To-Do

### Continue with the menu loop
