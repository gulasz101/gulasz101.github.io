---
layout: post
title: "LazyVim for PHP development"
date: 2023-10-08
tags: lazyvim vim nvim lsp php
---
### LazyVim for php devs -> minimal setup

So everyone from time to time likes to try out different thinks, for different reasons. I for instance made poor decision and had to stay with shitty laptop for 3 years in company. This is how I got into nvim.

Below I will share my findings and what in my humble opinion is the easiest way to get into php development with nvim.

### Setup expectations:

First we need to setup realistic expectations, what we want from our editor:
- code highlighting and autocompletion;
- code refactoring capabilities;
- navigation through code (go to definition, find usages etc);
- fuzzy search;
- autoformatting;
- static analysis;
- executing tests;
- editing `composer.json` with autocompletion and syntax checking;

## Why LazyVim?

Overall nvim distributions are super opinionated and have tons of customizations. So at the end you are not working with nvim, and standard plugin configurations but basically with every distribution you are using nvim, but it is like new ide with different set of key maps and always different behaviour.
What is best about it? It does all heavy lifting of orchestrating plugins and plugins configurations, keeping sane keymaps and setting as well allowing you to modify/disable any plugin without much effort.

Why not to go with OEM nvim? It is simple, there are tons of plugins, and you will simply get lost trying figure out what is golden set of plugins that you need. With LazyVim you have set of what you most likely you will need, over time you will change it to own configuration anyway, but kickstart will be way less painful.

## How to start?

### Context

- All action below I'm performing on arch linux. 
- I am also using LazyVim at work on my macbook pro (late 2019, so pre ARM), so all the steps should be easy to reproduce.
- I have also installed php 8.2 on my host operating system as for performing php code analysis is just way more convenient from host.
- I have installed [composer](https://getcomposer.org/download/) on my host machine so it is just more convenient to work that way without having to [run any docker images](https://hub.docker.com/_/composer) every time I need to perform some action.
- I am using [WezTerm](https://wezfurlong.org/wezterm/index.html) as it renders super fast and works cross platform (works great also in W11). 

### Basics
Ofc from the most important part:
```shell
vimtutor
```
It will take you 30 minutes to get up to speed with vim movements, trust me, you can skip it now, but you will eventually do it.
And this actually can be fun! Check out video:
<iframe width="100%" height="380" src="https://www.youtube.com/embed/y6VJBeZEDZU?si=-gJsCpJOyj3q9fKI" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

After having some fun you can go and finally install [LazyVim](https://www.lazyvim.org/installation). Steps are rather straightforward

### Key tools

- **Language Server** with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) -> w need to have language servers configured that will provide us all necessary help during code editing, what is language server protocol you can read [here](https://microsoft.github.io/language-server-protocol/)
- **Tree-sitter** with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) -> for better code highlighting, overall Tree-sitter is super powerful tool that can build concrete syntax tree, to read more about it go [here](https://tree-sitter.github.io/tree-sitter/)

### Setup in context of LazyVim

#### LSP

LazyVim comes with preconfigured [nvim-lspconfig](https://www.lazyvim.org/plugins/lsp#nvim-lspconfig), 
what we need to do is just to extend this configuration so it we are sure we have all language server installed.
To do so we have to create following file:
```lua
-- ~/.config/nvim/lua/plugins/lspconfig.lua

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- make sure mason installs the server
      servers = {
        jsonls = {
          -- lazy-load schemastore when needed
          on_new_config = function(new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = {
                enable = true,
              },
              validate = { enable = true },
            },
          },
        },
        intelephense = {},
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  }
}
```

What happens above? We are making sure LazyVim will install for us language servers for:
- json -> jsonls
- docker -> dockerls, docker_compose_language_service,
- php -> intelephense (strongly recommend to pay **12 EUR** for getting license and all the functionalities!!),

To be sure jsonls will have access to all the schemas (for example composer.json schema) files from [JSON Schema Store](https://www.schemastore.org/json/) and not having to download them manuall we have to enable one plugin called `b0o/SchemaStore.nvim`.
We can do it by adding following file to our LazyVim configuration.

```lua
-- ~/.config/nvim/lua/plugins/schemastore.lua

return {
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
}
```

Last part is to add some LazyVim specific configuration:

```lua
-- ~/.config/nvim/lua/config/lazy.lua
-- look for similar lines and extend them respectively
require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.json" },
    -- import/override with your plugins
    { import = "plugins" },
  },

```

#### Code highlighting

Now as we have already code autocompletion and basic diagnostics delivered, we can instrument our LazyVim installation to provide us better code highlighting.
To do so we have to extend Tree-sitter configuration by creating following file:
```lua
-- ~/.config/nvim/lua/plugins/treesitter.lua

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "php",
        "json",
        "json5",
        "jsonc",
        "dockerfile",
      })
    end,
  },
}
```
#### Static analysis and code formatting

**intelephense** is great, but it provides only basic code diagnostics as well as formatting in rather relaxed approach to PSR-12.

To improve quality of our code and overall of our live we will instrument LazyVim to use following tools.
As there is not OEM approach to do use those tools within neovim we are going to use another language server that can execute any binary on our OS and translate it's output to diagnostics.
The one and only! **[null-ls](https://github.com/nvimtools/none-ls.nvim)**.

Before getting into configuration of language server we need to have some executables in our system first.
- phpstan
```shell
composer global require phpstan/phpstan
```
- php-cs-fixer
```shell
composer global require friendsofphp/php-cs-fixer
```
For cs fixer I propose to keep configuration in composer home directory:

```php
// ~/.config/composer/.php_cs_fixer.php

<?php
/*
 * This document has been generated with
 * https://mlocati.github.io/php-cs-fixer-configurator/#version:3.34.0|configurator
 * you can change this configuration by importing this file.
 */
$config = new PhpCsFixer\Config();
return $config
    ->setRiskyAllowed(true)
    ->setRules([
        '@PHP74Migration' => true,
        '@PHP80Migration' => true,
        '@PHP80Migration:risky' => true,
        '@PHP81Migration' => true,
        '@PHP82Migration' => true,
        '@PSR12' => true,
        '@PSR2' => true,
        '@PhpCsFixer' => true,
        '@Symfony' => true,
    ])
    ->setFinder(PhpCsFixer\Finder::create()
        // ->exclude('folder-to-exclude') // if you want to exclude some folders, you can do it like this!
        ->in(__DIR__)
    )
;
```
##### Having two steps above done we can instrument **null-ls** to perform diagnostics and formatting.
To do so we have to edit following file.
```lua
-- ~/.config/nvim/lua/plugins/nonels.lua

return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      local composer_globa_dir = vim.fn.expand("$HOME/.config/composer")
      local composer_global_bin_dir = composer_globa_dir .. "/vendor/bin"

      vim.list_extend(opts.sources,
        {
          nls.builtins.formatting.phpcsfixer.with({
            command = composer_global_bin_dir .. "/php-cs-fixer",
            extra_args = {
              "--config",
              composer_globa_dir .. "/.php_cs_fixer.php",
            },
          }),
          nls.builtins.diagnostics.phpstan.with({
            command = composer_global_bin_dir .. "/phpstan",
            extra_args = { "-l", "max" },
          }),
        }
      )
    end,
  },
}

```
#### Executing tests

Last part we want to cover it a way to execute tests without switching to another terminal.

This we can achieve thanks to LazyVim integration with [neotest](https://github.com/nvim-neotest/neotest)

Setup is relatively simple, we can do it just by following [docs from LazyVim](https://www.lazyvim.org/extras/test/core).

But to wrap things in single place I will simply add config file here:

```lua
-- ~/.config/nvim/lua/plugins/neotest.lua
return {
  { "olimorris/neotest-phpunit" },
  {
    "nvim-neotest/neotest",
    opts = { adapters = { "neotest-phpunit" } },
  },
}
```
We have to not only to add neotest, but as well we have to install phpunit adapter for neotest. [neotest-phpunit](https://github.com/olimorris/neotest-phpunit).
There is also one available for pest.

Keep in mind we have to add plugin for lazy general config:
```lua
-- ~/.config/nvim/lua/config/lazy.lua
-- look for similar lines and extend them respectively
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.test.core" },
    { import = "plugins" },
  },
})
```
#### Docker linting
```lua
-- ~/.config/nvim/lua/plugins/lint.lua
return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        dockerfile = { "hadolint" },
      },
    },
  }
}
```
```lua
-- ~/.config/nvim/lua/config/lazy.lua
-- look for similar lines and extend them respectively
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "plugins" },
  },
})
```

### Summary

Having all steps above done correctly you are able now to use nvim with your code very pleasant way.

<video width="100%" preload="metadata" controls="">
  <source src="/assets/screencasts/2023-10-08-screencast.webm" type="video/webm; codecs=vp8, vorbis">
</video>
