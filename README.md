# XXXDownload

> [!IMPORTANT]
> The main branch of this repository is contains a lot of bugs because of lack
> of any tests. If you want to use this tool, please use the
> [v0.3.0](https://github.com/c477y/adulttime_dl/tree/v0.3.0) branch.

Bulk download porn videos from premium websites

## Note

> [!WARNING] Until the changes on this branch are not merged into master,
> consider this branch as a work in progress. I am currently in the process of
> refactoring this project by reducing complexity and making it easier to
> maintain. Tests are also added for sites for easier maintenance.

## Installation

This library is not exported to [RubyGems](https://rubygems.org) and has to be
run locally. Clone the repository and build the project.

You need to install ruby to build the project. Check the version you need in
[.ruby-version](.ruby-version) and install the appropriate version.

Run the below snippet to clone the project

```shell
git clone https://github.com/c477y/adulttime_dl.git xxx_download
cd xxx_download
```

Then, fetch all dependencies

```shell
bundle install
```

Finally, run the tool using the executable

```shell
./exe/xxx_download help
```

## Download Usage

The given sites are supported by the tool. All names are case sensitive and have
to be used as the first argument to the `download` command.

* [adulttime](https://members.adulttime.com)
* [archangel](https://www.archangelvideo.com/)
* [blowpass](https://www.blowpass.com/en)
* [cumlouder](https://www.cumlouder.com/)
* ~~[goodporn](https://goodporn.to/)~~ site has been removed
* [houseofyre](https://houseofyre.com/)
* [julesjordan](https://www.julesjordan.com/trial/)
* [loveherfilms](https://www.loveherfilms.com/tour/)
* [manuelferrara](https://manuelferrara.com/trial/)
* [pornfidelity](https://www.pornfidelity.com/)
* [rickysroom](https://rickysroom.com/)
* [s3xus](https://s3xus.com/)
* [scoregroup](https://score-group.com/)
* [spizoo](https://www.spizoo.com/)
* [ztod](https://www.zerotolerancefilms.com/en) (Zero Tolerance Films)

The tool will look for a config file whenever it's run. For first run, you can
generate a new config file by just running the command and don't pass the
`--config` flag. The tool will create a config file for you.

```shell
$ xxx_download download julesjordan
[INFO ] ----------------------------------------------------------------------------------------------------
[INFO ] Config option not passed to app and no config file detected in the current directory.
[INFO ] Generating a blank configuration file to config.yml This app will now exit.
[INFO ] Check the contents of the file and run the app again to start downloading.
[INFO ] ----------------------------------------------------------------------------------------------------
```

```shell
Usage:
  xxx-download download _site_

Options:
      [--help], [--no-help], [--skip-help]
                                            # Default: false
      [--cookie-file=COOKIE_FILE]           # Path to the file where the cookie is stored
      [--downloader=DOWNLOADER]             # Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'
      [--store=STORE]                       # Path to the .store file which tracks which files have been downloaded. If not provided, a store file will be created by the CLI
  -p, [--parallel=N]                        # Number of parallel downloads to perform. For optimal performance, do not set this to more than 5
                                            # Default: 1
  -l, [--log-level=LOG_LEVEL]               # Log level. Can be one of extra, trace, debug, info, warn, error, fatal
                                            # Default: info
                                            # Possible values: extra, trace, debug, info, warn, error, fatal

Description:
  Acceptable _site_ names: adulttime, archangel, blowpass, cumlouder, goodporn, houseofyre, julesjordan, loveherfilms, manuelferrara, pornve, rickysroom, s3xus, scoregroup, spizoo, ztod
```

### Options

#### --cookie-file=COOKIE_FILE

> [!NOTE] Starting with v0.3.0-rc1, `julesjordan`, `manuelferrara`,
> `rickysroom`, `s3xus`, `spizoo` and `ztod` do not need you to manually fetch the cookies
> from the website. The tool will automatically spawn a headless browser session
> that will ask your login credentials and store them in a file for reuse.

If you want to download from a premium website (one that requires a membership),
you would need to get your session cookie. If you use Mozilla Firefox, you can
use the extension[
cookies.txt](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/) to
store your session cookies to a text file. Login to the website using your
credentials and use the extension to download your cookies to a file (preferably
named `cookies.txt`). When you can the tool, it will look for the cookie file in
the current directory. Alternatively, you can pass in your cookie file by
passing the parameter `--cookie=../path/to/cookie/file.txt`

#### --downloader=DOWNLOADER

The tool uses external tools to download videos. Currently it supports
~~`youtube-dl`~~, `yt-dlp` or `wget`. Download ~~youtube-dl from
[https://youtube-dl.org/](https://youtube-dl.org/)~~ or download `yt-dlp` from
[https://github.com/yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp).

> [!IMPORTANT]
> Prefer using `yt-dlp` since `youtube-dl` has been deprecated.
> Support for `wget` is experimental and doesn't support resume downloads. Only
> use it if `yt-dlp` is not working.

You need to ensure that the tool is available in your $PATH. One way to verify
is executing `which youtube-dl` in your shell. If you don't see an error, you're
all set. Also ensure that you have the dependencies required by the downloader
(usually ffmpeg and ffprobe). This is required to decrypt HLS streams. By
default, the tool will use youtube-dl.

#### --store=STORE

The tool tracks all downloads in a file called `adt_download_status.store`. DO
NOT edit this file and preferably don't delete it as well. This is used to
prevent downloading duplicate scenes. By default, the tool will look for this
file in the current directory and will create one if it's not present.

#### --parallel=N

Support parallel downloads to speed up the process. By default this value is 1.
Do not increase this to a high number or the adulttime API will rate limit you.

#### --log-level

Indicate the level of logging. The default value is `info`. You can set the
following values: `extra`, `trace`, `debug`, `info`, `warn`, `error` and
`fatal`. `extra` will push a lot of logs so it's recommended to use this for
debugging or raising issues.

## FAQ

### Are all supported sites require a premium membership?

No, sites like `goodporn` and `cumlouder` are free to use and don't require a
premium membership.

### How do I get my session cookie?

Refer to [the cookie](# --cookie-file=COOKIE_FILE) section for more information.
Some sites like `s3xus` and `rickysroom` support dynamic session authentication
and will not require you to manually get your session cookie. Instead, using
these sites will spawn a browser window where you can login and the tool will
get the cookies automatically.

### Can XXX site be supported?

It depends on the site. The tool uses two strategies to download from sites:

* Using the site's APIs: if available, this is the first choice as it's most
  reliable
* Using HTML parsing: this is a fallback is the site doesn't have an API. This
  is less reliable as it makes the site prone to breaking if the site layout
  changes.
* Using browser automation: this is the last resort as it uses a browser to
  navigate the site. Usually this is required if the site does not allow
  downloads or have HLS streams. This method makes the site slow (as controlling
  a browser is slow in itself) and prone to breaking as it still uses HTML
  parsing (although with a different library).

## Ran into an error?

Raise an issue in the [issue
tracker](https://github.com/c477y/adulttime_dl/issues) and I'll try to help out.
However, please understand that debugging paid sites require a paid membership
account which I may not have access to so my support may be limited.
