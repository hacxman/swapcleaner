module Main
where

import Control.Monad
import Control.Concurrent

import System.IO

--import System.SysInfo
import System.Process

data MemPropp = MemTotal Int
             | MemFree Int
             | MemAvailable Int
             | SwapTotal Int
             | SwapFree Int
             | Empty
             deriving (Show, Read, Eq)

data MemProp = MemProp {
                memTotal :: Int
               ,memFree :: Int
               ,memAvailable :: Int
               ,swapTotal :: Int
               ,swapFree :: Int }
             deriving (Show, Read, Eq)


strToProp ("MemTotal:" : x : _) = MemTotal $ read x
strToProp ("MemFree:" : x : _) = MemFree $ read x
strToProp ("MemAvailable:" : x : _) = MemAvailable $ read x
strToProp ("SwapTotal:" : x : _) = SwapTotal $ read x
strToProp ("SwapFree:" : x : _) = SwapFree $ read x
strToProp _ = Empty

dropEmpty props = filter (/=Empty) props



strToProp' p ("MemTotal:"     : x : _) = p { memTotal = read x }
strToProp' p ("MemFree:"      : x : _) = p { memFree = read x }
strToProp' p ("MemAvailable:" : x : _) = p { memAvailable = read x }
strToProp' p ("SwapTotal:"    : x : _) = p { swapTotal = read x }
strToProp' p ("SwapFree:"     : x : _) = p { swapFree = read x }
strToProp' p _ = p

emptyProp = MemProp 0 0 0 0 0

run' = do
  hnd <- openFile "/proc/meminfo" ReadMode
  cont <- hGetContents hnd
  let meminfo = foldl (\x y -> strToProp' x $ words y) emptyProp $ lines cont
--  print meminfo
  let swapOcc = swapTotal meminfo - swapFree meminfo

  hnd <- openFile "/proc/loadavg" ReadMode
  cont <- hGetContents hnd
  let loads = words cont
  let onemin = read $ loads !! 0 :: Double
  let fivemin = read $ loads !! 1 :: Double
  ncores <- getNumCapabilities
--  print ncores
  when (onemin < fromIntegral ncores && fivemin > onemin) $ do
    when ((swapTotal meminfo > 0) && (swapOcc > 100000) && (memAvailable meminfo > swapOcc)) $ do
      print meminfo
      putStrLn "Condition met, flipping swap"
      callCommand "echo swapoff /swapfile"
      callCommand "swapoff /swapfile"
      callCommand "echo swapon /swapfile"
      callCommand "swapon /swapfile"

--  when ((swapTotal meminfo > 0) && (swapOcc > 1000) && (memAvailable meminfo > swapOcc)) $ do


  return ()

--run = do
--  val <- sysInfo
--  either (\_ -> return ())
--         (\v -> do
--             print v
--             print $ totalram v
--             print $ freeram v
--             print $ sharedram v
--             print $ bufferram v
--             print $ memUnit v
--             putStr "    "
--             print $ totalram v - (sharedram v)
--             print $ totalswap v
--             print $ freeswap v
--             putStr "sw: "
--             print $ totalswap v - freeswap v
--             return ())
--         val

main = do
      forever $ run' >> threadDelay 1000000
