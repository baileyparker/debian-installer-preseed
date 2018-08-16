# Debian Preseeded Installer Builder

Author: **[Bailey Parker](https://github.com/baileyparker)**

Create preseeded Debian installer ISOs for multiple architectures.


## Usage

This should be run on a Debian machine.

You can ensure you have the needed dependencies for this tool by running
`sudo make install-deps`.

Modify `RELEASE` and `ARCHES` to contain the Debian release version number
(ex. 9.5.0) and desired architectures, respectively (should match the
[names and numbers used by Debian][1]).

You can alternatively pass these as ENV vars of the same name.

Then run:

```
$ make all
```

Preseeded ISOs will be built and placed in `build/`. By default, this will
build complete (suitable for offline machines) and netinst ISOs for each
architecture. If you don't want the complete ISOs, pass `OFFLINE=0`. If you
don't want the netinst ISOs, pass `NETINST=0`.

```
# Build only the netinst ISOs for each arch
$ make OFFLINE=0 all
```

### Make a single ISO

To make a single ISO for a specific version and architecture, you can invoke:

```
$ make build/preseed-debian-9.5.0-amd64-xfce-CD-1.iso
```

To make a `netinst` ISO, try:

```
$ make build/preseed-debian-9.5.0-amd64-netinst.iso
```

The names must match [the names used by the debian mirror][2] prefixed with
`preseed-` (the arch amd64 is linked as an example, but you can specify a
filename for any arch). Products will be placed in `build/`.

#### Verifying SHA512 Digest & GPG Signature

By default, the SHA512 digests of the images downloaded and the GPG signatures
on these digests are verified. Verifying the GPG signatures requires you to
have `gpg` installed and to have the Debian signing key in your keyring. As of
writing, this can be achieve with:

```
$ gpg --keyserver keyring.debian.org --recv-keys DF9B9C49EAA9298432589D76DA87E80D6294BE9B
```

But, you should [check the Debian documentation][3] to ensure this key is still
valid.

If you'd like to skip checking the GPG signature, provide `VERIFY_SIGNATURE=0`.
If you'd like to skip checking the SHA512 digest, provide `VERIFY_DIGEST=0`.
Note that skipping digest verification will automatically skip signature
verification as well (`VERIFY_DIGEST=0` implies `VERIFY_SIGNATURE=0`).


#### Using a Different Mirror

By default, images are downloaded from `https://cdimage.debian.org`. To change
this invoke with `MIRROR`.

```
$ make MIRROR=https://mirrors.kernel.org/debian-cd all
```

The `MIRROR` should be the URL of the `debian-cd` directory. That is,
`"${MIRROR}/current/amd64/iso-cd/SHA512SUMS"` should exist.

[A list of CD image mirrors][4] can be found on the Debian website.


### Upgrading Releases

  1. Invoke `make diff`. This will show you what you changed in your
     `preseed.cfg`. Take note of all of the changes you made. (You could also
     consult your git history)

  2. Update the `RELEASE` file to the Debian release to which you are
     upgrading. `RELEASE` should contain the version number (ex.
     `9.5.0`).

  3. Run `make pull-preseed-cfg`. **This will overrite your existing
     `preseed.cfg`!**

  4. Open `preseed.cfg` in your favorite editor and manually re-add the changes
     you discovered from step 1. Take note of any new configuration options
     added by this Debian release.

  5. Finally run `make all` to remake all of your ISOs.


### Clean

`make clean` will clean everything. To just clean the cache of ISOs downloaded
from the mirror, try `make clean-cache`. To just clean the built preseeded
ISOs, invoke `make clean-build`.


## Requirements

Can be installed with `sudo make install-deps`.

  - `bsdtar`
  - `cpio`
  - `coreutils`
  - `diff`
  - `gpg`
  - `gzip`
  - `isolinux`
  - `md5sum`
  - `sha512sum`
  - `wget`
  - `xorriso`


## License

See `LICENSE`.


## Notes

  - This tool mostly follows the [Debian guide for making preseed ISOs][5]


  [1]: https://cdimage.debian.org/debian-cd/current/
  [2]: https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/
  [3]: https://www.debian.org/CD/verify
  [4]: https://www.debian.org/CD/http-ftp/#mirrors
  [5]: https://wiki.debian.org/DebianInstaller/Preseed/EditIso
