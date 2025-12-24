# Edit on local with livereload

## Install

> [!WARNING]
> As I am using [jekyll-theme-chirpy](https://github.com/cotes2020/jekyll-theme-chirpy)
> I need to install nodejs, easiest way to get it with [nvm](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating)

### Ruby setup

#### Fedora

* `sudo dnf install ruby ruby-devel`
* `gem install bundler`

### macos

```sh
# install rbenv
brew install rbenv ruby-build

# init rbenv
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
# For Bash: echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
source ~/.zshrc # Or restart your terminal

rbenv install 3.4.8 # Or another version like 3.3.3
rbenv global 3.4.8

# restart env or source ~/.zshrc
# ❯ ruby -v
# ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
```

## Run it on Local

* `bundler update && bundler install`
* `bundler exec jekyll s --livereload`
* [localhost](http://localhost:4000/)

> [!IMPORTANT]
> After every edit of `_config.yml`
> it is required to execute `bundle exec jekyll build`

> [!NOTE]
>Link to page: [https://gulasz101.github.io/](https://gulasz101.github.io/)
