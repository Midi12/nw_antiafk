# nw_antiafk

A passive New World Anti AFK script.

# How does it works?

You choose a set interval which the program will choose from randomly.
Every now and then the program will send inputs to the game to prevent AFK.

# But they filter out simulated inputs, right?

Yeah bro.
But the flutter runner (c++ part) for this program has been modified to register a global input hook in order to remove the simulated flag from inputs.
Global input hooks are system wide hooks that are called in reverse order of registration hence why the application renew the global input hook on a set interval.

# How do I use it?

Should be trivial.

# How do I compile it?

Install Dart and Flutter.
Clone the repository.
Run `flutter packages get` to install the packages.
Run `flutter build windows` to build the windows application (only platform supported).

# Notice
The game must be in focus for the program to work.