BSDTAR?=bsdtar
CPIO?=cpio
DIFF?=diff
GPG?=gpg
GZIP?=gzip
MD5SUM?=md5sum
SHA512SUM?=sha512sum
WGET?=wget
XORRISO?=xorriso

# Build complete ISOs (for offline use) when invoking `make all`.
# Pass OFFLINE=0 to disable building these.
OFFLINE?=1

# Build netinst ISOs when invoking `make all`.
# Pass NETINST=0 to disable building these.
NETINST?=1

# Mirror for images.
# "$(MIRROR)/current/amd64/iso-cd/SHA512SUMS" should exist.
MIRROR?=https://cdimage.debian.org/debian-cd

# Verify the SHA512 digest of the images.
# Pass VERIFY_DIGEST=0 to skip digest verification.
VERIFY_DIGEST?=1

# Verify the signature on the SHA512 digest of the images.
# The Debian signing key must be in your keyring:
#
#   https://www.debian.org/CD/verify
#
# Pass VERIFY_SIGNATURE=0 to skip signature verification.
# Signatures are not verified if VERIFY_DIGEST=0 is provided.
VERIFY_SIGNATURE?=1

# Debian release version for which to build installer ISOs (ex. 9.5.0)
RELEASE?=$(shell cat RELEASE)

# Space separated list of architectures for which to build installer ISOs
# (ex. amd64 arm64)
ARCHES?=$(shell cat ARCHES)


# -----------------------------------------------------------------------------
# End of configurable Make variables
# -----------------------------------------------------------------------------

RELEASE_MAJOR:=$(shell echo $(RELEASE) | sed 's/\..*$$//')

# Make ENV vars available to donwload_iso.sh and preseed_iso.sh
export BSDTAR CPIO DIFF GPG MD5SUM SHA512SUM WGET XORRISO VERIFY_DIGEST \
	VERIFY_SIGNATURE

# NOTE: gzip path can't be called GZIP, because when run, gzip treats an ENV
# var named GZIP as extra CLI args. This is so you can pass compression levels
# into programs that use gzip. The fact that you can pass anything beyond the
# compression settings is a very *interesting* "feature."
export GZIP_=$(GZIP)

# Constants derived from configurable variables above
EXAMPLE_PRESEED:=https://www.debian.org/releases/$(RELEASE_MAJOR)/example-preseed.txt

# = is important, interpolation is done at usage, which allows us to use make
# to build URLs in the cache/debian-%.iso target
ISO_URL=$(MIRROR)/$(RELEASE)/$(ARCH)/iso-cd/debian-$(RELEASE)-$(ARCH)-$(TYPE).iso

ISOS:=

ifneq ($(RELEASE), )
ifneq ($(ARCHES), )
ISO_PREFIXES:=$(addprefix preseed-debian-$(RELEASE)-,$(ARCHES))

ifeq ($(OFFLINE),1)
	ISOS+=$(addsuffix -xfce-CD-1.iso,$(ISO_PREFIXES))
endif

ifeq ($(NETINST),1)
	ISOS+=$(addsuffix -netinst.iso,$(ISO_PREFIXES))
endif
else
	$(warning No RELEASE specified, try modifying the RELEASE file or ENV var)
endif
else
	$(warning No ARCHES specified, try modifying the ARCHES file or ENV var)
endif


# Builds an offline ISO and netinst ISO for each arch in ARCHES for the Debian
# release with version RELEASE. Pass NETINST=0 to not build the netinst ISOs.
# Pass OFFLINE=0 to not build the (larger) complete ISOs.
all: $(addprefix build/,$(ISOS))

# Installs the dependencies needed to run this tool
install-deps:
	apt install bsdtar coreutils isolinux wget xorriso

# Build a specific preseeded Debian installer ISO. The name after the preseed-
# prefix must match those used by the Debian mirror:
# https://cdimage.debian.org/debian-cd/current/amd64/
build/preseed-%.iso: cache/%.iso preseed.cfg
	$(eval ISO_PATH=$<)
	$(eval PRESEED=$(lastword $^))

	mkdir -p $(@D)
	./preseed_iso.sh $(ISO_PATH) $(PRESEED) $@

# Trick to get a space in a variable
# https://stackoverflow.com/a/4735256/568785
empty:=
space:=$(empty) $(empty)

# cache/debian-RELEASE-ARCH-TYPE-OTHER_JUNK.iso
# RELEASE, ARCH, and TYPE are interpolated by make (see ISO_URL)
cache/debian-%.iso:
	$(eval PARTS=$(subst -,$(space),$(shell basename $@ .iso)))
	$(eval RELEASE=$(word 2,$(PARTS)))
	$(eval ARCH=$(word 3,$(PARTS)))
	$(eval TYPE=$(subst $(space),-,$(wordlist 4,$(words $(PARTS)),$(PARTS))))

	mkdir -p $(@D)

	./download_iso.sh $@ $(ISO_URL)

# Cleans built preseeded ISOs and ISOs cached from the Debian mirror
clean: clean-build clean-cache

# Cleans built preseeded ISOs
clean-build:
	rm -rf build

# Cleans ISOs cached from the Debian mirror
clean-cache:
	rm -rf cache

# diff the preseed.cfg with the example preseed.cfg on Debian's website.
#
# Useful when upgrading to a new release to see what you have changed so you
# can replicate the same changes in the new preseed.cfg.
diff: preseed.cfg
	wget -O - $(EXAMPLE_PRESEED) | $(DIFF) -u $< - || true

# Replace preseed.cfg with the example preseed from the Debian website.
pull-preseed-cfg:
	wget -O preseed.cfg $(EXAMPLE_PRESEED)

# Lint shell scripts with shellcheck
test:
	shellcheck *.sh

.PHONY: all install-deps clean clean-build clean-cache diff pull-preseed-cfg \
	test
