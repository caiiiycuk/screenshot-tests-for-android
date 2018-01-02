FILES_WITH_VERSIONS = \
	gradle.properties \
	examples/app-example/build.gradle \
	examples/app-example-androidjunitrunner/build.gradle \
	plugin/src/main/groovy/com/facebook/testing/screenshot/build/ScreenshotsPlugin.groovy

OLD_VERSION=$(shell grep VERSION_NAME gradle.properties |  cut -d '=' -f 2)

TMPFILE:=$(shell mktemp)

.PHONY:
	@true

set-release:
	[ x$(NEW_VERSION) != x ]
	[ x$(OLD_VERSION) != x ]
	for file in $(FILES_WITH_VERSIONS) ; do \
		test -f $$file ; \
	done
	for file in $(FILES_WITH_VERSIONS) ; do \
		sed -i 's/$(OLD_VERSION)/$(NEW_VERSION)/' $$file ; \
	done

old-release:
	echo $(OLD_VERSION)

cleanup:
	rm -rf ~/.m2/repository/com/facebook/testing/screenshot/
	./gradlew plugin:clean core:clean layout-hierarchy-common:clean layout-hierarchy-litho:clean

release-tests: integration-tests
	./gradlew :releaseTests

integration-tests: |  cleanup install-local app-example-tests app-example-androidjunitrunner-tests cleanup
	@true

app-example-tests:
	./gradlew app-example:screenshotTests 2>&1 | tee $(TMPFILE)

	grep "Found 3 screenshots" $(TMPFILE)

app-example-androidjunitrunner-tests:
	./gradlew app-example-androidjunitrunner:screenshotTests 2>&1 | tee $(TMPFILE)

	grep "Found 6 screenshots" $(TMPFILE)

app-example-litho-tests:
	./gradlew app-example-litho:screenshotTests 2>&1 | tee $(TMPFILE)
	grep "Found 1 screenshots" $(TMPFILE)

install-local:
	./gradlew :plugin:install
	./gradlew :core:install
	./gradlew :layout-hierarchy-common:install
	./gradlew :layout-hierarchy-litho:install

version-tag:
	git tag v$(OLD_VERSION)
	git push origin v$(OLD_VERSION)

prod-integration-tests: env-check
	$(MAKE) cleanup
	cd examples/app-example && ./gradlew connectedAndroidTest
	cd examples/app-example && ./gradlew screenshotTests
