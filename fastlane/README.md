fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios unit_tests
```
fastlane ios unit_tests
```
Run all the Unit Test
### ios generate_code_coverage
```
fastlane ios generate_code_coverage
```
Generate Code Coverage HTML files (via Slather)
### ios submit_code_coverage_to_codecov
```
fastlane ios submit_code_coverage_to_codecov
```
Generate (via Slather) and submit Code Coverage to codecov.io
### ios bump_patch_version
```
fastlane ios bump_patch_version
```
Update the patch number
### ios publish_podspec
```
fastlane ios publish_podspec
```
Publish the podspec
### ios patch_and_publish_podspec
```
fastlane ios patch_and_publish_podspec
```
Update the patch number and publish the podspec

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
