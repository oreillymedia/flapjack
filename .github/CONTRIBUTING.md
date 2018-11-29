# Contributing guidelines

So you've decided to contribute to Flapjack? That's great! We'd love to have you lend a hand and make our project even better.


## Git flow

If you're outside the O'Reilly organization, then this one is a no brainer, but if you _are_ part of the O'Reilly organization, we prefer that you fork this repository to your personal GitHub account before you work on it. Perform your changes in a separate branch, push that branch to your personal repository, and then open a pull request from your branch to our main repository. In short:

1. Fork to your personal GitHub account
2. Create a separate branch off `master`
3. Commit your changes (more on this below)
4. Push branch up to your personal GitHub account
5. Open a pull request against our main repository

When we approve your pull request, we will merge it into our `master` branch using GitHub's "squash-and-merge" functionality, which will combine your commits into a single commit, tagged with the pull request number.

Additionally, you'll probably want to add our upstream main repository as a git remote to the one you've got sitting on your machine. It's easy!

```bash
$ git remote add upstream https://github.com/oreillymedia/flapjack.git
```

Then any time you want to make your `master` match our `master`:

```bash
$ git fetch upstream master
$ git reset --hard upstream/master
```

It's always a great idea to make sure and perform this step before you start working on any new branches. It will likely save you rebase/merge headaches when it comes time to integrate your changes with our repository.


## Commits

We'd prefer your commit messages follow a certain format. For super-simple changes, a one-line commit statement will do just fine, provided you keep it under 72 characters. For more complex changes, a simple one-line description under 72 characters should be in the first line, followed by 2 line breaks, and then a more detailed description of the changes in as many lines or paragraphs as you see fit.


## Coding conventions and linting

We've got SwiftLint integration with our project which should define the coding conventions we like to stick to in this repository, and we expect all pull requests submitted should pass a linter check. If you've got CocoaPods installed and your `Pods` directory is up-to-date (it should be!), then Xcode will automatically run the linter as part of the normal build process, and any warnings will be revealed to you right within Xcode.


## Questions

If you've got any questions at all, please reach out to us! Our contact information is [at the bottom of our README](https://github.com/oreillymedia/flapjack#authors).