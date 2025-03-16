# Edit on local with livereload

## Install

> [!WARNING]
> As I am using [jekyll-theme-chirpy](https://github.com/cotes2020/jekyll-theme-chirpy)
> I need to install nodejs, easiest way to get it with [nvm](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating)

### Ruby setup

* `sudo dnf install ruby ruby-devel`
* `gem install bundler`

## Run it on Local

* `bundler update && bundler install`
* `bundler exec jekyll s --livereload`
* [localhost](http://localhost:4000/)

> [!IMPORTANT]
> After every edit of `_config.yml`
> it is required to execute `bundle exec jekyll build`

> [!NOTE]
>Link to page: [https://gulasz101.github.io/](https://gulasz101.github.io/)
