# Shock

### Warning: This library is not supported by Just Eat Takeaway anymore and therefore considered deprecated. The repository has been archived.

An HTTP mocking framework written in Swift.

## DemoApp

The DemoApp is a sample app that shows how to use the Shock framework.

- `Test Shock`: will show how to emebed Shock in your app and how to use it to mock API calls.
- `Test ShockRecorder`: will show how to use ShockRecorder to record API calls and how to use the recorded API calls to mock API calls during UI Tests.

### Recording API calls with ShockRecorder

To record API calls during the demo app execution, enable the `SAVE_API_RESPONSES_ON_DISK` argument passed on launch in the `DemoApp` scheme.

Once the flag is enabled, the API responses will be saved in the `data_responses` folder, you can find the path in the console logs, e.g.

```
[ShockRecorder] filePath: file:///Users/user/Library/Developer/CoreSimulator/Devices/BE295F5C-5D11-4C70-A74E-52AF3389F0C9/data/Containers/Data/Application/A49E2BCB-1E12-4A34-8DE8-9262742BC564/Documents/data_responses/2023-09-23-16-23-31_001_GET_api_breeds_image_random.json
```

To record API calls during the UITests execution:

- Uncomment the line ```app.launchArguments.append("SAVE_API_RESPONSES_ON_DISK")```
- Make sure that UI Test are not executed in parallel.
- Run the UI Tests (They should fail as the API response changes every time)
- Fix the UI Tests with the new API responses, if you want to adapt them the new responses.
- Copy the new API responses from `data_responses/UITests` folder to `Demo/UITests/Resources/RecordedMocks` folder once you want to update the old API responses.
