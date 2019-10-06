# awesome-prgma-2019
iOS App for #PragmaConf example of on demand builds via Slack

## Getting started

Make sure you have the latest Xcode command lines tools
Run:
```
xcode-select --install
```

### Create project and initialize Fastlane

- Create your Xcode project / Move into an existing one
- `cd "~/your_project_folder“` the your project directory
- [Install Fastlane following the official guide](https://docs.fastlane.tools/getting-started/ios/setup)
- Copy the Fastfile from the example
  - [in case you need help/inspiration/more info](https://docs.fastlane.tools/advanced/lanes/)

### dotenv

Dotenv convention wants you to make files following its convention, which is **absolutely** the way you should go for if you have one project to mantain. In the case studied and explained in the talk, I've mentioned about different environment, projects, variables, so I had to adapt the **dotenv** loading to be controlled manually.
That's why in the project we'll show how to tailor it having:
- targets (clients)
- build configuration (development, staging, uat, production)

#### Reminder: in the example Fasfile is used the manually loaded procedure.

- Create your dotenv files following the **standard** convention
  - .env (root file)
  - .env.development (development file) .env.staging and so on…

- Create your dotenv files following the **manually laded** files
  - .env (root file)
  - [client]-[environment].env (i.e. - ClientA-Staging.env) and so on…

#### Populate .env file

Open the newly created `.env` file and paste this line:

```
ENV_VAR_TEST=Hi there I'm an EVN VAR loaded from the root dotenv file 😁 !
```

#### Testing time 🤞🏽👨🏼‍⚕️

Lets see if our journey is going well, let's try to launch a **fastlane action** from the terminal.
Reminder: you must be in the project directory.

```
bundle exec fastlane test_dotenv
```

That's how the output should look like:

![](/res/testing_dotenv.gif)
