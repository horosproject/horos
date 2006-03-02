#	@(#)Makefile	1.3	5/3/91

ARCH=		Solaris
DSTDIR=		..
MANDIR=		$(DSTDIR)/man
INCDIR=		$(DSTDIR)/include
BINDIR=		$(DSTDIR)/test
LIBDIR=		../$(DSTDIR)/$(ARCH)/lib
LINTLIBDIR=	$(LIBDIR)/lint

CPPFLAGS=	-I$(INCDIR) -I../.. -D_NO_LONGLONG
CFLAGS=		-g
LINTFLAGS=	-hb

SOURCES= 	decompoptimise.c \
		huffcoptimisebug.c \
		huffdoptimise.c \
		jpegutil.c \
		mcu.c \
		pmreadoptimise.c \
		pnmtoljpoptimisebug.c \
		predict.c \
		read.c \
		write.c

LIBRARY=	libJpglless.a

OBJECTS=	$(SOURCES:%.c=$(ARCH)/%.o)

$(LIBDIR)/$(LIBRARY): createdir $(OBJECTS)
		ar rv $@ $(OBJECTS)

lint:		$(SOURCES)
		$(LINT.c) $(SOURCES)


createdir:	
		test -d $(ARCH) || mkdir -p $(ARCH)
		test -d $(DSTDIR)/$(ARCH)/lib || mkdir -p $(DSTDIR)/$(ARCH)/lib

clean:
		-rm -Rf $(ARCH)

.KEEP_STATE:
.INIT:	$(LIBDIR) $(ARCH)
$(LIBDIR) $(ARCH) :
		test -d $@ || mkdir -p $@

$(ARCH)/%.o: %.c
		$(COMPILE.c) $< -o $@

