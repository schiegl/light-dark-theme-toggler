# Toggle between light and dark themes system wide

As of now it will change themes for:

* GTK & icons (only for XFCE, but more DEs can be added easily)
* XFCE4 Terminal
* Rofi
* Intellij IDEA 2016.1 CE

The script takes options:

* toggle: switches to dark if light is applied and the other way around
* time: Looks at the time and switches based on your time preferences

The time option becomes interesting in combination with a systemd timer and service which can switch automatically. Here is how you would set up them up:

1. Create a service `~/.config/systemd/user/toggle-theme.service`:

	[Unit]
	Description=Change theme based on current time

	[Service]
	Type=oneshot
	ExecStart=/usr/bin/sh /path/to/light-dark-theme-toggler.sh

	[Install]
	WantedBy=multi-user.target

2. Create a timer `~/.config/systemd/user/toggle-theme.timer`:

	[Unit]
	Description=Change theme based on current time

	[Timer]
	OnBootSec=1
	OnActiveSec=1h

	[Install]
	WantedBy=timers.target

3. Enable the timer `systemctl --user enable switch-theme.timer`

This was more of an experiment to see what shell scripting was like than anything else. In addition to that I had to get by with man pages because the internet was not not accessible at the time of coding this. Anyway... I am now scarred for life, but hopefully it turned out well enough to be of use for you.
