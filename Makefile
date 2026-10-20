clean-release:
	rm '~/Library/Containers/com.fespinozacast.projects.youtube.DoneWhen/Data/Library/Application\ Support/release-store.sqlite'

clean-all:
	rm -rf '~/Library/Containers/com.fespinozacast.projects.youtube.DoneWhen'
	sudo rm -rf /Applications/DoneWhen.app
