module Hackern.Interactive.Shell where

import Hackern.Interactive.SendHandle
import Hackern.Interactive.FSHandle
import Hypervisor.XenStore
import Control.Monad.Reader
import Hypervisor.Debug
import Control.Concurrent
import Halfs.Monad
import Hypervisor.Console
import Hackern.Interactive.ShellState
import Prelude hiding (getLine)

-- The REPL shell loop
runShell shellState@(ShellState_ here xs con) fsState = do
  let console str = writeConsole con $ str ++ "\n"
  me <- xsGetDomId xs
  console $ "Welcome to Hackern system! I am " ++ show me ++ "\n"
  console $ "Valid commands: quit, ls, cd, mkdir, discover\n"
  _ <- runHalfs fsState (loop shellState)
  return ()

loop shellState@(ShellState_ here xs con) = do
  lift $ writeConsole con (here ++ "> ")
  inquery <- lift $ getLine con

  let dispatch f = f shellState >>= loop

  case words inquery of
    ("quit":_)     -> return ()
    ("ls"  :_)     -> dispatch handleLs
    ("cd"  :x:_)   -> dispatch $ handleCd x
    ("mkdir":x:_)  -> dispatch $ handleMkdir x
    ("discover":_) -> dispatch handleDiscover
    _ -> do
      lift $ writeConsole con "Unrecognized command\n"
      loop shellState


getLine con = do
  nextC <- readConsole con 1
  writeConsole con nextC
  case nextC of
    "\r" -> writeConsole con "\n" >> return ""
    [x]  -> (x:) `fmap` getLine con
    _    -> fail "More than one character back?"


