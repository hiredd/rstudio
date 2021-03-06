#!/usr/bin/env Rscript

## This should be run via the build-xterm script, not directly.
##
## Tweaks the css that comes with xterm.js so it can be overriden by Ace editor
## themes, copying the modified file to the RStudio source directory.

#setwd("~/rstudio/src/gwt/tools/xterm.js/src")
outDir <- "../../../src/org/rstudio/studio/client/workbench/views/terminal/xterm"
baseName <- "xterm.css"

content <- suppressWarnings(readLines(baseName))

findNext <- function(regex, content, start = 1, end = length(content)) {
   matches <- grep(regex, content, perl = TRUE)
   matches[(matches > start) & (matches < end)][1]
}

## Delete the @keyframes rules. Each one contains nested braces.
deleteKeyFrames <- function(content) {
   keyFramesStarts <- grep("@keyframes", content, fixed = TRUE)
   if (length(keyFramesStarts) != 2) {
      warning("No '@keyframes' in file '", baseName, "'; stopping", call. = FALSE)
      quit(status = 1)
   }
   keyFramesStarts <- sort(keyFramesStarts, decreasing = TRUE)
   for (keyFrameStarts in keyFramesStarts) {
     keyFrameEnds <- keyFrameStarts
     openCount <- 1
     while (openCount > 0) {
       keyFrameEnds = keyFrameEnds + 1
       if (grepl("}", content[keyFrameEnds], fixed = TRUE) == TRUE &&
           grepl("{", content[keyFrameEnds], fixed = TRUE) == TRUE) {
        ## Line had both { and }, no-op 
       } else if (grepl("}", content[keyFrameEnds], fixed = TRUE) == TRUE) {
         openCount = openCount - 1
       } else if (grepl("{", content[keyFrameEnds], fixed = TRUE) == TRUE) {
         openCount = openCount + 1
       }
     }
     content <- content[-(keyFrameStarts:keyFrameEnds)]
   }
   content
}

deleteTwoLineRule <- function(content, ruleName1, ruleName2, ruleName3, ruleName4) {
   match <- paste("^\\s*\\.", ruleName1, "\\s*\\.", ruleName2, ",\\s*$", sep = "")
   firstLineMatch = grep(match, content, perl = TRUE)
   if (length(firstLineMatch) != 1) {
      return(content)
   }
   match <- paste("^\\s*\\.", ruleName3, "\\s*\\.", ruleName4, "\\s*{", sep = "")
   secondLineMatches = grep(match, content, perl = TRUE)
   if (length(secondLineMatches) == 0) {
      return(content)
   }
   if (is.element(firstLineMatch + 1, secondLineMatches)) {
      nextBraceLoc <- findNext("}", content, start = firstLineMatch)
      if (length(nextBraceLoc) == 1) {
         return(content[-(firstLineMatch:nextBraceLoc)])
      }
   }
   content
}

deleteRule <- function(content, ruleName1, ruleName2 = NULL) {
   if (!is.null(ruleName2)) {
      match <- paste("^\\s*\\.", ruleName1, "\\s*\\.", ruleName2, "\\s*{", sep = "")
   } else {
      match <- paste("^\\s*\\.", ruleName1, "\\s*{", sep = "")
   }
   ruleLoc <- grep(match, content, perl = TRUE)
   nextBraceLoc <- findNext("}", content, ruleLoc)
   
   content[-(ruleLoc:nextBraceLoc)]
}

## Make the adjustments
content <- deleteKeyFrames(content)
content <- deleteRule(content, "terminal")
content <- deleteRule(content, 
               "terminal:not\\(\\.xterm-cursor-style-underline\\):not\\(\\.xterm-cursor-style-bar\\)", 
               "terminal-cursor")
content <- deleteTwoLineRule(content,
               "terminal.xterm-cursor-style-bar", "terminal-cursor::before",
               "terminal.xterm-cursor-style-underline", "terminal-cursor::before")
content <- deleteRule(content, "terminal", "xterm-viewport")
content <- deleteRule(content, "terminal:not\\(\\.focus\\)", "terminal-cursor")

## Write it out.
outputPath <- file.path(outDir, baseName)
cat(content, file = outputPath, sep = "\n")
quit(status = 0)
