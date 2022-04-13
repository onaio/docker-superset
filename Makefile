REPO                      := onaio/superset
STAGES                    := final
SUPERSET_VERSION          := 1.3.2
SUPERSET_KETCHUP_VERSION  := v0.2.1
UPSTREAM_SUPERSET_VERSION := 1.3.2

.PHONY: default clean clobber latest push

default: latest

.docker:
	mkdir -p $@

.docker/$(SUPERSET_VERSION)-%: | .docker
	docker build \
	--build-arg NODE_VERSION=$(NODE_VERSION) \
	--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
	--build-arg SUPERSET_VERSION=$(SUPERSET_VERSION) \
	--build-arg SUPERSET_KETCHUP_VERSION=$(SUPERSET_KETCHUP_VERSION) \
	--build-arg UPSTREAM_SUPERSET_VERSION=$(UPSTREAM_SUPERSET_VERSION) \
	--iidfile $@ \
	--tag $(REPO):$(SUPERSET_VERSION)-$* \
	--target $* \
	.

.docker/latest .docker/$(SUPERSET_VERSION): .docker/$(SUPERSET_VERSION)-final
.docker/%:
	docker tag $$(cat $<) $(REPO):$*
	cp $< $@

clean:
	rm -rf .docker

clobber: clean
	docker image ls $(REPO) --quiet | uniq | xargs docker image rm --force

demo: .docker/$(SUPERSET_VERSION)
	docker run --detach \
	--name superset-$(SUPERSET_VERSION) \
	--publish 8088:8088 \
	$$(cat $<)
	docker exec -it superset-$(SUPERSET_VERSION) superset-demo
	docker logs -f superset-$(SUPERSET_VERSION)

latest: .docker/latest .docker/$(SUPERSET_VERSION)

push:
	-docker push $(REPO):$(SUPERSET_VERSION)
	-docker push $(REPO):latest
