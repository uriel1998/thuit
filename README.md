# thuit

A system to find and prune desktop files in appropriate XDG areas.

## Contents
 1. [About](#1-about)
 2. [License](#2-license)
 3. [Prerequisites](#3-prerequisites)
 4. [Installation](#4-installation)
 5. [Usage](#5-usage)
 6. [TODO](#6-todo)

***

## 1. About

I love the idea of `.desktop` files in the XDG standard. 

I *hate* that there are so many implementations and locations they might 
be, and so few programs that make sure the shortcuts are removed.  I got 
tired of duplicate and broken `desktop` files all over the place, and 
as much as I like it, the "fix broken desktop files" cleaner with 
`bleachbit` wasn't cutting it.

As with most of my programs, this is meant to be simple and easy to 
adapt to your particular situation, rather than me trying to anticipate 
your setup.  It's pretty heavily commented bash scripting.

`thuit` is an anglicization of  þveit, meaning "cleared area".  

## 2. License

This project is licensed under the Apache License. For the full license, see `LICENSE`.

## 3. Prerequisites

* bash
* find
* sed 
* sort
* cut

## 4. Installation


## 5. Usage

-c - analyze crossover desktop files inside crossover installation (off by default)
-n - Look for multiple desktop files with the same program name
-e - Look for multiple desktop files with the same executable line
-b - Look for desktop files with invalid executables
-f $FILENAME - write output to $FILENAME


-c - Check desktop files inside a Crossover installation directory 


Does NOT look at wine-extension* desktop files; causes way too many false positives

## 6. TODO


### Roadmap:

* interactive chooser
* automatic chooser (with backup, of course)
* priorities with interactive chooser
* Full list of desktop files and attributes
* Find ones with bad/missing executables
* Be able to output/find based on desktop attribute
* Pruning mechanism after review
* exact match versus find in