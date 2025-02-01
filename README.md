# LinuxTools
This is a collection of small tools I have created to automate repetitive tasks. Most people who run Linux develop such utilities, and like many others I am sharing a few in hopes they may be useful to others.

Although written with an eye toward reuse, the goal was to meet my own requirements. You may need to adapt the tools to your own system and needs. The most common things you might need to adapt are:
* Paths and filename constants are sometimes embedded. Generally, I follow Linux Standard Base (LSB) directory layouts. Truly generalized design would have paths read from config files or provided as command arguments, but since I wrote these for my own use, I often store paths as constants within the code. These are nearly always at the beginning of the file.
* Shebang lines ("#!/usr/bin/bash" and similar) occur as the very first line of a script and indicate what executable should be chosen by the Linux shell to interpret the rest of the script. Your system may have a different location for these, so you may need to edit the shebang line.

These have been written over many years of using Linux. Some of the code uses syntax or design patterns that were sensible at the time but have better alternatives now. I would love to learn from examples of better ways to do things, and you're welcome to fork this repo and offer a pull request (PR). The only caveat I have is that these are intended as personal tools, so I may not accept a PR that breaks my own use of the tool.
