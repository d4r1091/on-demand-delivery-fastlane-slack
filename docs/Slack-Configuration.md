## Configuring a new Slack Bot step-by-step

- Make sure you have have signed-in your Slack web

### Bot Integration Step-by-step guide

- Go to [Slack apps](https://api.slack.com/apps)
- Click on **Create an App**
- You should now see this 👇

![](/res/slack_create_app.png)

- Fill in with your app Name: mine will be `PragmaBot`
- In the dropdown Development Slack Workspace select the workspace you'd like to install your Bot in

![](/res/pragma_bot_workspace_selection.png)

- Now it's time to add a Bot and Permission to interact with the Slack APIs

![](/res/adding_slackbot_features.png)

- Let's start by selecting _Bots_ from the section above
- Then in the new window select **Add a Bot User**

![](/res/adding_slackbot_user.png)

- After given it a name, let's click on **Add Bot User**
- Going back to the page containing Features and functionalities we should have a green checkmark ✅ for Bots
- Let's select Permissions then and move down to **Scopes**
- Select **Add an OAuth Scope** then add
  - bot
  - chat:write:bot

![](/res/slackbot_scopes.png)

- Next team is to Install the app in our workspace. To do so:
  - move back to the Basic Information page
  - select _Install your app to your workspace_
  - follow instructions

At the end of the process, going back in _Permissions_, you'll have generated two tokens

- OAuth Access Token
- Bot User OAuth Access Token

The one we will need in case we want to setup [corebot](https://github.com/outofcoffee/corebot) is _Bot User OAuth Access Token_
It will look like the one below (as shown in Corebot's [README](https://github.com/outofcoffee/corebot#creating-a-slack-app))

`xoxp-123456789012-123456789012-abcdef1234567890abcdef1234567890`

Add this as environment variable `SLACK_AUTH_TOKEN` before initializing Corebot.

### Incoming Webhook for Fastlane

Now it's time to store the SLACK_URL environment variable (which the Fastlane action [slack](https://docs.fastlane.tools/actions/slack/) will use to communicate within our Slack)
We have setup it within our root `.env` file.
You can either have it stored within your CD provider environment variable configuration, it's up to you.

To achieve so:

- Go to [Slack apps](https://api.slack.com/apps)
- Select your App
- On the right panel, under **Features**, select **Incoming Webhooks**
- Then activate it by turning the switch on
- Now click on **Add new Webhook to Workspace**
- Select the Slack channel you want to connect it to
- You'll get back a Webhook URL
- Copy that one and evaluate the environment variable `SLACK_URL` with it

The format will be the following:

`SLACK_URL=https://hooks.slack.com/services/[SLACK_APP_ID]/[SLACK_APP_VERIFICATION_TOKEN]`

Enjoy! 🎉
