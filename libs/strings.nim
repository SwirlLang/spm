import utilities/[tlib]
import std/[strformat, strutils]

const
    red* = rgb(255,33,81)
    green* = rgb(37,255,100)
    yellow* = rgb(246,255,69)
    blue* = rgb(105,74,255)
    dft* = def()

var
    helpMenu* = &"""
{red}SPM{dft} version {blue}0.0.1{dft}
{red}Swirl Package Manager{dft} is the official package management tool for the {blue}Swirl{dft} programming language.

{red}USAGE{dft}:
    spm [OPTIONS] [ARG]

{red}OPTIONS{dft}:"""

proc error*(str: string) =
    stdout.writeLine &"{dft}[{red}ERROR{dft}]      {str}"
    quit(1)

proc info*(str: string) =
    stdout.writeLine &"{dft}[{blue}INFO{dft}]       {str}"

proc warn*(str: string) =
    stdout.writeLine &"{dft}[{yellow}WARN{dft}]       {str}"

proc ask*(str: string):string =
    return read(&"{dft}[{yellow}PROMPT{dft}]     {str}{blue}")

proc success*(str: string) =
    stdout.writeLine &"{dft}[{green}SUCCESS{dft}]    {str}" 

proc registerHelp*(calls: array[0..1,string], desc:string) =
    let options = calls.join(", ")
    let thing = &"\n    {blue}{options}{dft}"
    let space = " ".repeat(50-len(thing))
    help_menu &= thing & space & desc