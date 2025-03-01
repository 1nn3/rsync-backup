prefix ?= ~/.local

bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
mandir ?= $(prefix)/share/man
sharedir ?= $(prefix)/share/rsync-backup

all:

install:
	install -D rsync-backup $(DESTDIR)$(bindir)/rsync-backup
	install -D rsync-backup.1 $(DESTDIR)$(mandir)/man1/rsync-backup.1
	install -D tripwire-wrapper $(DESTDIR)$(bindir)/tripwire-wrapper
	install -D tripwire-wrapper.1 $(DESTDIR)$(mandir)/man1/tripwire-wrapper.1
	install -D smartcheck $(DESTDIR)$(bindir)/smartcheck
	install -D smartcheck.1 $(DESTDIR)$(mandir)/man1/smartcheck.1

uninstall:
	-rm -f $(DESTDIR)$(bindir)/rsync-backup
	-rm -f $(DESTDIR)$(mandir)/man1/rsync-backup.1
	-rm -f $(DESTDIR)$(bindir)/tripwire-wrapper
	-rm -f $(DESTDIR)$(mandir)/man1/tripwire-wrapper.1
	-rm -f $(DESTDIR)$(bindir)/smartcheck
	-rm -f $(DESTDIR)$(mandir)/man1/smartcheck.1

clean:

distclean: clean

.PHONY: all install clean distclean uninstall

