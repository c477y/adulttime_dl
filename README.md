# AdultTimeDL

> [!IMPORTANT]
> The main branch of this repository is contains a lot of bugs because of lack
> of any tests. If you want to use this tool, please use the
> [v0.3.0](https://github.com/c477y/adulttime_dl/tree/v0.3.0) branch.

Bulk download porn videos from premium websites

## Installation

This library is not exported to [RubyGems](https://rubygems.org) and has to be
run locally. Clone the repository and build the project.

You need to install ruby to build the project. Check the version you need in
[.ruby-version](.ruby-version) and install the appropriate version.

Run the below snippet to clone the project

```shell
git clone https://github.com/c477y/adulttime_dl.git
cd adulttime_dl
```

Then, fetch all dependencies

```shell
bundle install
```

Finally, run the CLI using the executable

```shell
./exe/adulttime_dl help
```

## Download Usage

When I started the project, only downloads from
[members.adulttime.com](https://members.adulttime.com) was supported. Overtime,
support for multiple sites was added and currently supports downloading from
these sites:

* [adulttime](https://members.adulttime.com)
* [archangel](https://www.archangelvideo.com/)
* [blowpass](https://www.blowpass.com/en)
* [goodporn](https://goodporn.to/)
* [houseofyre](https://houseofyre.com/)
* [julesjordan](https://www.julesjordan.com/trial/)
* [loveherfilms](https://www.loveherfilms.com/tour/)
* [manuelferrara](https://manuelferrara.com/trial/)
* [scoregroup](https://score-group.com/)
* [ztod](https://www.zerotolerancefilms.com/en) (Zero Tolerance Films)

The CLI will look for a config file whenever it's run. For first run, you can
generate a new config file by just running the command and don't pass the
`--config` flag. The CLI will create a config file for you.

```shell
$ adulttime_dl download julesjordan
[INFO ] ----------------------------------------------------------------------------------------------------
[INFO ] Config option not passed to app and no config file detected in the current directory.
[INFO ] Generating a blank configuration file to config.yml This app will now exit.
[INFO ] Check the contents of the file and run the app again to start downloading.
[INFO ] ----------------------------------------------------------------------------------------------------
```

```shell
Usage:
  adulttime_dl download _site_

Options:
     [--help], [--no-help]
     [--cookie-file=COOKIE_FILE]    # Path to the file where the cookie is stored
     [--downloader=DOWNLOADER]      # Name of the client to use to download. Can be either 'youtube-dl'(default) or 'yt-dlp'
     [--download-dir=DOWNLOAD_DIR]  # Directory where the files should be downloaded. Defaults to current directory
     [--store=STORE]                # Path to the .store file which tracks which files have been downloaded. If not provided, a store file will be created by the CLI
  p, [--parallel=N]                 # Number of parallel downloads to perform. For optimal performance, do not set this to more than 5
                                    # Default: 1
     [--quality=QUALITY]            # Quality of video to download. Allows 'sd', 'hd' or 'fhd'
  c, [--config=CONFIG]              # Path to YAML file with download filters Defaults to config.yml in the current directory
                                    # Default: config.yml
  v, [--verbose], [--no-verbose]    # Flag to print verbose logs. Useful for debugging

Description:
  Acceptable _site_ names: adulttime, archangel, blowpass, cumlouder, goodporn, houseofyre, julesjordan, loveherfilms, manuelferrara, pornve, scoregroup, sxyporn, ztod
```

### Options

#### --cookie-file=COOKIE_FILE

If you want to download from a premium website (one that requires a membership),
you would need to get your session cookie. If you use Mozilla Firefox, you can
use the extension[
cookies.txt](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/) to
store your session cookies to a text file. Login to the website using your
credentials and use the extension to download your cookies to a file (preferably
named `cookies.txt`). When you can the CLI, it will look for the cookie file in
the current directory. Alternatively, you can pass in your cookie file by
passing the parameter `--cookie=../path/to/cookie/file.txt`

#### --downloader=DOWNLOADER

The CLI uses external tools to download videos. Currently it supports
`youtube-dl` or `yt-dlp`. Download youtube-dl from
[https://youtube-dl.org/](https://youtube-dl.org/) or download `yt-dlp` from
[https://github.com/yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp).

You need to ensure that the tool is available in your $PATH. One way to verify
is executing `which youtube-dl` in your shell. If you don't see an error, you're
all set. Also ensure that you have the dependencies required by the downloader
(usually ffmpeg and ffprobe). This is required to decrypt HLS streams. By
default, the CLI will use youtube-dl.

#### --download-dir=DOWNLOAD_DIR

The directory where you want to download the scenes. By default, the CLI will
download videos in the current working directory.

#### --store=STORE

The CLI tracks all downloads in a file called `adt_download_status.store`. DO
NOT edit this file and preferably don't delete it as well. This is used to
prevent downloading duplicate scenes. By default, the CLI will look for this
file in the current directory and will create one if it's not present.

#### --parallel=N

Support parallel downloads to speed up the process. By default this value is 1.
Do not increase this to a high number or the adulttime API will rate limit you.

#### --quality=QUALITY

Quality of videos to download. Accepts `fhd`, `hd` or `sd`. If a higher
resolution video is not available, the CLI will download the next available
resolution. Defaults to `hd`,

#### --verbose

Print verbose logs. Useful for debugging.

## Ran into an error?

The CLI has no tests as it's not possible to test behavior for sites that
require membership without having an actual membership. Changes to existing site
clients are extremely rare but if you run into an error, create an issue with
the stacktrace. If it's something breaking on CLI backend, it can be fixed.
However, if the error happens inside the site indexer (example, when a site
changed it's web layout and the site indexer uses HTML parsing), it won't be
easy to fix the issue and you might need to do some debugging on your own.
However, you should open an issue as it will allow other contributors to look
into the issue.
