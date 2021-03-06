{-# LANGUAGE NumericUnderscores #-}
module Main
where

import Control.Monad
import Control.Concurrent

import System.IO

import System.Process

swap_trigger_size = 500000 -- 500MB
run_every = 10_000_000 -- 10 sec


data MemProp = MemProp {
                memTotal :: Int
               ,memFree :: Int
               ,memAvailable :: Int
               ,swapTotal :: Int
               ,swapFree :: Int }
             deriving (Show, Read, Eq)

strToProp p ("MemTotal:"     : x : _) = p { memTotal = read x }
strToProp p ("MemFree:"      : x : _) = p { memFree = read x }
strToProp p ("MemAvailable:" : x : _) = p { memAvailable = read x }
strToProp p ("SwapTotal:"    : x : _) = p { swapTotal = read x }
strToProp p ("SwapFree:"     : x : _) = p { swapFree = read x }
strToProp p _ = p

emptyProp = MemProp 0 0 0 0 0

run = do
  hnd <- openFile "/proc/swaps" ReadMode
  cont <- hGetContents hnd
  let swaplines = map words $ tail $ lines cont
  let swap_devices = map head swaplines
  putStrLn $ "swaps: " ++ unwords swap_devices

  hnd <- openFile "/proc/meminfo" ReadMode
  cont <- hGetContents hnd

  let meminfo = foldl (\x y -> strToProp x $ words y) emptyProp $ lines cont
  let swapOcc = swapTotal meminfo - swapFree meminfo


  hnd <- openFile "/proc/loadavg" ReadMode
  cont <- hGetContents hnd

  let loads = words cont
  let onemin = read $ loads !! 0 :: Double
  let fivemin = read $ loads !! 1 :: Double

  ncores <- getNumCapabilities

  -- load is decreasing
  when (onemin < fromIntegral ncores && fivemin > onemin) $ do
    -- there is enough available memory to read in whole swap
    -- and swap is sufficiently filled
    when ((swapTotal meminfo > 0) && (swapOcc > swap_trigger_size) && (memAvailable meminfo > swapOcc)) $ do
      print meminfo
      putStrLn "Condition met, flipping swap"
      forM_ swap_devices $ \swap_device -> do
        callCommand $ "echo swapoff " ++ swap_device
        callCommand $ "swapoff " ++ swap_device
      forM_ swap_devices $ \swap_device -> do
        callCommand $ "echo swapon " ++ swap_device
        callCommand $ "swapon " ++ swap_device

  return ()

main = do
      forever $ run >> threadDelay run_every
