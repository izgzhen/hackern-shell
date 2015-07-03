module Hackern.Interactive.Repl where

import Hackern.Interactive.SendHandle
import Hackern.Interactive.FSHandle
import Hypervisor.XenStore
import Control.Monad.Reader
import Hypervisor.Debug
import Control.Concurrent
import Halfs.Monad
import Hypervisor.Console
import Prelude hiding (getLine)

-- The REPL shell loop
repl xs con debug here fsState = do
  let console str = writeConsole con $ str ++ "\n"
  me <- xsGetDomId xs
  console $ "Hello! This is an interactive Unix-like file-system shell for " ++ show me ++ "\n"
  console $ "Valid commands: quit, ls, cd, mkdir\n"
  debug "Starting interaction loop!\n"
  info <- runHalfs fsState _ -- (loop ) -- xs con here)
  return ()


loop xs con here = do
  let loop' = loop xs con here
  lift $ writeConsole con (here ++ "> ")
  inquery <- lift $ getLine con
  case words inquery of
    ("quit":_)    -> return ()
    ("ls"  :_)    -> handleLs here con loop'
    ("cd"  :x:_)  -> handleCd here con x xs loop
    ("mkdir":x:_) -> handleMkdir here x con loop'
    ("disvcover":_) -> handleDiscover xs con loop'
    _ -> do
      lift $ writeConsole con "Unrecognized command\n"
      loop'

getLine con = do
  nextC <- readConsole con 1
  writeConsole con nextC
  case nextC of
    "\r" -> writeConsole con "\n" >> return ""
    [x]  -> (x:) `fmap` getLine con
    _    -> fail "More than one character back?"


