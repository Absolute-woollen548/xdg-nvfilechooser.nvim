# :penguin: `XDG-NVFilechooser.nvim`

A Linux XDG-portal filepicker backend and Neovim plugin to pick any file using popular Neovim pickers.

## What is this?

There is nothing that infuriates me more, after a nice Neovim and [vimium](https://chromewebstore.google.com/detail/dbepggeogbaibhgnhhndojpepiihcmeb?utm_source=item-share-cb) session, to be faced with the forsaken **Upload** button. _Sigh_.

Maybe I'm uploading my resume for a job, an image for an online editor. A video file on Google Drive, etc...

Whatever it is, I have to slowly navigate my file tree, using the Gnome or GTK file picker that comes pre-installed with other portal backends. And oh boy if that file is deeply nested. Absolute mouse-clicking horror.

If I'm uploading a file, I'm almost certain of the name of the file I'm going to upload. I also have an idea of where it is in. Why not fuzzy find for it?

I pretty much use fuzzy finding for all my Neovim navigation, why not bring that to XDG?

A video tells a thousand words:

## Requirements

- **Neovim** >= 0.9.4
- for proper icons support:
- [mini.icons](https://github.com/nvim-mini/mini.icons) _(optional)_
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) _(optional)_
- a [Nerd Font](https://www.nerdfonts.com/) **_(optional)_**
