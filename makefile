
build:
	docker build . --tag count-org-loc:latest

run: build
	docker run --rm -it -v $(pwd):/src count-org-loc:latest myUserOrMyOrg
