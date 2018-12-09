# company-popup

A very simple front end for `company-mode` using `popup` package. I really
wanted the quick tips that `autocomplete` provides, but not the `autocomplete`
itself. Another option was `company-quickhelp`, but that package does not work
in terminal which I use exclusively. So I wrote this to have both auto
completion and quick tips.

This is still in progress and not a complete package yet, and I'm still
developing it.

To use add these two lines to your Emacs init.el file:

```elisp
('require company-popup)
(setq company-popup-mode t)
```
