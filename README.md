# Building Shorten URL service

## Context
Suppose you start working at CoinGecko and the first project you are asked to work on involves building a url shortener service. This application should behave similarly to https://bitly.com or https://tinyurl.com. The hypothetical team for this project would consist of yourself, another frontend engineer, a designer, and a product owner.

### Requirements:
- The length of the shortened path should start from 2 letters and be unique.
- The website should be able to redirect the user to the original url.
- Stakeholder wants to do some data analytics.
- A simple and neat UI (use any CSS, with or without frameworks)

## Part 1: Planning the deliveries
We will meet with stakeholders every week for the progress. It would be good to have a demonstrable during each meeting.
Please describe how you would plan the project and a high level design of the architecture. What principles or design practices would you consider incorporating into the process and technology? You can include diagrams. You do not need to write any code for this problem.

## Part 2: Implementation: Be able to submit URL to be shortened, Shortened URL should redirect, an index page to list the URLs with simple analytics

### Requirements:
- Use Git version control to commit your changes. (You may create a Gitlab account, create a free private repository, and add us as collaborators). We encourage you to commit often and lay out your thought process in the commit messages clearly.
- The app should be deployed and can be accessed from a public facing URL.
- Please write test cases against the functions implemented.
- Provide instructions for setup and launch. (It’s usually a README file)

### Please note that you can use your familiar stack for this part. For your information, we use
- Ruby on Rails as the language and framework
- PostgreSQL for datastore
- Redis for cache
- Heroku for deployment

## Submission

### Code commits
- If you are using a framework and it has boilerplate code generation I would suggest creating the initial commit to separate the boilerplate code from yours
- Commit often this would help convey your thought process virtually
- Branch out of the master branch and create a Merge Request. We can go through the code and discuss there

