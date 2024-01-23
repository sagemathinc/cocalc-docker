# ChatGPT

CoCalc-docker has ChatGPT integration.  To enable it for all users
you must obtain a ChatGPT API Key from OpenAI.  Then create an admin
user on CoCalc, open the Site Settings section of the Admin settings
page, and do two things:

1. Enable the OpenAI ChatGPT UI setting.
2. Enter your OpenAI API key.

![](.chatgpt.md.upload/paste-0.41776237425550544)

<br/>

Once this is done you'll see a ChatGPT box on the landing page and there
is ChatGPT integration in any CoCalc chatroom, which you can use via @chatgpt.

## Costs

_**It's suprisingly affordable!**_  There is a [discussion here](https://github.com/sagemathinc/cocalc-docker/discussions/188) about costs.

## GPT-4

GPT-4 is expensive, and by default there is a cost configured with cocalc-docker, which is just inherited from how cocalc.com works.  Get around this as follows:

Question (see https://github.com/sagemathinc/cocalc-docker/issues/217):
> It seems I'm unable to add "money" to my balance or to allow negative balance. Is it possible to turn this feature off, disable the check or fake-add "money" to my own account?

It is possible to add fake money or allow a negative balance.    To add money, one way is to sign up for stripe, then put in stripe credentials for a test account and then you get to use any fake stripe testing card.  

If you make a cocalc admin account as explained [here](https://github.com/sagemathinc/cocalc-docker/blob/master/README.md#make-a-user-an-admin), you can set the min balance of any user in the admin page like this -- find the user (yourself), then click "Purchases", then click "Minimum Allowed Balance..." and set it to something very negative:

<img width="1434" alt="image" src="https://github.com/sagemathinc/cocalc-docker/assets/1276278/6b43c838-8647-4dca-a251-42c89d70b181">
