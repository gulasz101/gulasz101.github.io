Source code with own Dockerfile for local writing.
Just to not forget:
* `docker build --tag jekyll39 .`
* `docker run --rm --volume "./:/srv/jekyll" -p 4000:4000 -p 35729:35729 jekyll39 jekyll serve --livereload`
