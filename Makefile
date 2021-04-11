all: swapcleaner

swapcleaner: swapcleaner.hs
		ghc -threaded --make swapcleaner.hs -with-rtsopts="-N"
