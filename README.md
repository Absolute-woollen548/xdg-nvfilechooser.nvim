# :penguin: `XDG-NVFilechooser.nvim`

A Linux XDG-portal filepicker backend and Neovim plugin to pick any file using `snacks.picker` (for now)

## What is this?

There is nothing that infuriates me more, than after a nice Neovim and [vimium](https://chromewebstore.google.com/detail/dbepggeogbaibhgnhhndojpepiihcmeb?utm_source=item-share-cb) session, to be faced with an **Upload** button. _Sigh_.

Maybe I'm uploading my resume for a job, an image for an online editor, a video file on Google Drive, etc. Whatever it is, I have to slowly navigate my file tree using the Gnome or GTK file picker that comes pre-installed from my portal backend. And oh boy if that file is deeply nested. Absolute mouse-clicking horror.

If I'm uploading a file, I'm almost certain of its name and have an idea of where it lives. I pretty much use fuzzy finding for all my navigation, why not bring that to the file picker?

> [!IMPORTANT]
> Since I've built this mainly for my own usage, only the [snacks](https://github.com/folke/snacks.nvim) picker is supported for now.
> If this project gains traction and people actually start using it, I'll try to implement `fzf-lua` and `telescope` equivalents.
> With that said, I welcome contributaion.

A video tells a thousand words:

https://github.com/user-attachments/assets/b40088fd-122e-4fdb-99f7-8c724dc5db23

## Requirements

> [!NOTE]
> Unforunately, I've found that the `find` command sucks for this kind of thing. It gets the results depth-first, which is almost always what you don't want. The files you want are certain to be in the higher levels of the filesystem. I tried to do the same with `rg` but I couldn't find a way to make it select directories instead of files without a lot of hacks & pain. So that means that `fd` is required. Sorry.

- [**fd**](https://github.com/sharkdp/fd)
- [**snacks.picker**](https://github.com/folke/snacks.nvim)
- [**xdg-nvfilechooser**](https://github.com/shenawy29/xdg-nvfilechooser)
- `XDG_NVFILECHOOSER_TERMINAL` environment variable set to your termnial command.

## XDG Backend Installation

### For Nix users

**1. Add the flake as an input**

In your `flake.nix`, add `xdg-nvfilechooser` as an input:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  xdg-nvfilechooser.url = "github:shenawy29/xdg-nvfilechooser";
};
```

**2. Configure the XDG portal**

In your Home Manager configuration, add the following. This registers the portal backend, and tells xdg-desktop-portal to use it for `FileChooser`:

```nix
let
  xdg-nvfilechooser = inputs.xdg-nvfilechooser.packages.${pkgs.system}.default;
in {
  xdg = {
    enable = true;
    mime.enable = true;
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        xdg-nvfilechooser
      ];
      config = {
        # lowercase desktop from `echo $XDG_CURRENT_DESKTOP`
        hyprland = {
          "org.freedesktop.impl.portal.FileChooser" = [ "xdg-nvfilechooser" ];
        };
      };
    };
  };
}
```

**3. Rebuild your system**

---

### For Non-Nix users

The installation process is a bit involved, so bear with me.

**1. Install the binary**

Download the [**xdg-nvfilechooser**](https://github.com/shenawy29/xdg-nvfilechooser/releases) binary from the release page and place it in `/usr/local/bin`.

**2. Register the portal**

Create a `.portal` file so `xdg-desktop-portal` knows about the backend. Save the following to `/usr/share/xdg-desktop-portal/portals/xdg-nvfilechooser.portal`:

```ini
[portal]
DBusName=org.freedesktop.impl.portal.desktop.xdg-nvfilechooser
Interfaces=org.freedesktop.impl.portal.FileChooser
UseIn=gnome;kde;sway;hyprland
```

**3. Register the D-Bus activation file**

Save the following to `~/.local/share/dbus-1/services/org.freedesktop.impl.portal.desktop.xdg-nvfilechooser.service`:

```ini
[D-BUS Service]
Name=org.freedesktop.impl.portal.desktop.xdg-nvfilechooser
Exec=/usr/local/bin/xdg-nvfilechooser
SystemdService=xdg-nvfilechooser.service
```

This tells D-Bus how to activate the service by name, and that it maps to the systemd unit you'll create in the next step.

**4. Register the systemd user service**

Create a systemd user service file at `~/.config/systemd/user/xdg-nvfilechooser.service`:

```ini
[Unit]
Description=XDG NVFilechooser Portal Backend
PartOf=graphical-session.target

[Service]
Type=dbus
BusName=org.freedesktop.impl.portal.desktop.xdg-nvfilechooser
ExecStart=/usr/local/bin/xdg-nvfilechooser

[Install]
WantedBy=xdg-desktop-portal.service
```

**5. Enable and start the service**

```bash
systemctl --user daemon-reload
systemctl --user enable --now xdg-nvfilechooser
```

**6. Configure xdg-desktop-portal**

Edit `~/.config/xdg-desktop-portal/portals.conf` to tell the portal to use this backend for file picking:

```ini
[preferred]
org.freedesktop.impl.portal.FileChooser=xdg-nvfilechooser
```

Then restart the portal for changes to take effect:

```bash
systemctl --user restart xdg-desktop-portal
```

## Plugin Installation

```lua
return {
	"shenawy29/xdg-nvfilechooser.nvim",
	dependencies = {
		"folke/snacks.nvim",
	},
	config = function()
		require("xdg-nvfilechooser").setup({
			picker = "snacks",

			-- Already set by default. Goto_path for the rare case when you want to pick a file in the outside of $HOME.
			keymaps = {
				["<C-e>"] = { "goto_path", mode = { "n", "i" } },
			},
		})
	end,
}
```
