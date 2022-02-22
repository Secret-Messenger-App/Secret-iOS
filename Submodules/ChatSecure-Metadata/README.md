ChatSecure-Metadata
===================

Various metadata for ChatSecure


# Requirements
You will need a recent version of Ruby. We now use [deliver](https://github.com/KrauseFx/deliver) and [snapshot](https://github.com/KrauseFx/snapshot).

    $ gem install fastlane

# Generating Screenshots

Snapshot stuff has been moved to the main repository.

```
$ bundle exec fastlane screenshots
```

# Uploading Metadata

Moved to `fastlane` folder in the main repo.

```
$ bundle exec fastlane upload_screenshots
$ bundle exec fastlane upload_metadata
$ bundle exec fastlane upload_all
```

# Transifex

To synchronize translations use Transifex's `tx` tool.

    $ pip install transifex-client
    
This command will download all existing translations:

    $ tx pull -f
    
New languages on Transifex will need to be [manually mapped](http://docs.transifex.com/developer/client/config) to the correct language code folder in `./metadata`. This is because the language codes in Transifex don't match up with the ones that Apple uses.

    $ nano .tx/config
    
Available Languages Codes: https://github.com/KrauseFx/deliver#available-language-codes
    
    
# Updating What's New
    
Update release notes in the `Deliverfile` in the main repo.
    
# License

GPLv3