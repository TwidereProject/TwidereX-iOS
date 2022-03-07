# UITest Cookbook
There are some recipes for quick UITest.


## Onboarding

#### Twitter login

```zsh
# build and run test case for auto sign-in
TEST_RUNNER_email='<email>' \
  TEST_RUNNER_password='<password>' \
  xcodebuild \
  test \
  -workspace TwidereX.xcworkspace \
  -scheme 'TwidereX'  \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro Max' \
  -testPlan 'TwidereX' \
  -only-testing:TwidereXUITests/TwidereXUITests/testOnboardingTwitterLogin
```
