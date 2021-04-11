all: swapcleaner

swapcleaner: swapcleaner.hs
		ghc -threaded --make swapcleaner.hs -with-rtsopts="-N"

install: swapcleaner
		systemctl stop swapcleaner.service
		cp swapcleaner /usr/local/bin/swapcleaner

install-service: swapcleaner.service
		cp swapcleaner.service /etc/systemd/system/swapcleaner.service
