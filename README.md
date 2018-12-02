Schleuder, version 3
======================================

Schleuder is a gpg-enabled mailing list manager with resending-capabilities. Subscribers can communicate encrypted (and pseudonymously) among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.

Version 3 of schleuder is a complete rewrite, which aims to be more robust, flexible, and internationalized. It
also provides an API for the optional web interface called [schleuder-web](https://0xacab.org/schleuder/schleuder-web).

For more details see <https://schleuder.org/docs/>.

Requirements
------------
* ruby >=2.5
* gnupg >=2.2
* gpgme
* sqlite3
* openssl
* icu

*If you use Debian buster or CentOS 7, please have a look at the [installation docs](https://schleuder.org/schleuder/docs/server-admins.html#installation). We do provide packages for those platforms, which simplify the installation a lot.*

*🛈 A note regarding Ubuntu: All Ubuntu versions up to and including 17.10 don't meet the requirements with their packaged versions of gnupg! To run Schleuder on Ubuntu you currently have to install a more recent version of gnupg manually. Only Ubuntu 18.04 ("bionic") provides modern enough versions of Schleuder's requirements.*

On systems that base on Debian 10 ("buster"), install the dependencies via

    apt-get install ruby-dev gnupg2 libgpgme-dev libsqlite3-dev libssl-dev build-essential libicu-dev


We **recommend** to also run a random number generator like [haveged](http://www.issihosts.com/haveged/). This ensures Schleuder won't be blocked by lacking entropy, which otherwise might happen especially during key generation.

On Debian based systems, install it via

    apt-get install haveged


Additionally these **rubygems** are required (will be installed automatically unless present):

* rake
* active_record
* sqlite3
* thor
* thin
* mail-gpg
* sinatra
* sinatra-contrib


Installing Schleuder
------------

1. Download [the gem](https://schleuder.org/download/schleuder-3.6.0.gem) and [the OpenPGP-signature](https://schleuder.org/download/schleuder-3.6.0.gem.sig) and verify:
   ```
   gpg --recv-key 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3
   gpg --verify schleuder-3.6.0.gem.sig
   ```

2. If all went well install the gem:
   ```
   gem install schleuder-3.6.0.gem
   ```

3. Set up schleuder:
  ```
  schleuder install
  ```
  This creates necessary directories, copies example configs, etc. If you see errors about missing write permissions please follow the advice given.


For further information on setup and configuration please read <https://schleuder.org/schleuder/docs/server-admins.html>.


Command line usage
-----------------

See `schleuder help`.

E.g.:

    Commands:
      schleuder check_keys                    # Check all lists for unusable or expiring keys and send the results to the list-admins. (This is supposed...
      schleuder help [COMMAND]                # Describe available commands or one specific command
      schleuder install                       # Set up Schleuder initially. Create folders, copy files, fill the database, etc.
      schleuder version                       # Show version of schleuder
      schleuder work list@hostname < message  # Run a message through a list.

List administration
-------------------

Please use
[schleuder-cli](https://0xacab.org/schleuder/schleuder-cli) to create and
manage lists from the command line.

Optionally consider installing
[schleuder-web](https://0xacab.org/schleuder/schleuder-web), the web
interface for schleuder. It enables list-admins to manage their lists through
the web instead of using [request-keywords](https://schleuder.org/docs/#subscription-and-key-management).



Todo
----

See <https://0xacab.org/schleuder/schleuder/issues>.

Testing
-------
We use rspec to test our code. To setup the test environment run:


    SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bundle exec rake db:init

To execute the test suite run:

    bundle exec rspec

Please note: Some of the specs use 'pgrep'. On systems that base on Debian 10 ("buster") install it via 

    apt-get install procps

We are working on extendig the test coverage.

Contributing
------------

Please see [CONTRIBUTING.md](CONTRIBUTING.md).


Mission statement
-----------------

Please see [MISSION_STATEMENT.md](MISSION_STATEMENT.md).


Code of Conduct
---------------

We adopted a code of conduct. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).


License
-------

GNU GPL 3.0. Please see [LICENSE.txt](LICENSE.txt).


Alternative Download
--------------------

Alternatively to the gem-files you can download the latest release as [a tarball](https://schleuder.org/download/schleuder-3.6.0.tar.gz) and [its OpenPGP-signature](https://schleuder.org/download/schleuder-3.6.0.tar.gz.sig).
