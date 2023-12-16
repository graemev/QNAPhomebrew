LIB=.
LIBS=-L$(LIB)
CFLAGS       = -fPIC -ggdb3
LDFLAGS      = -shared $(LIBS)
RELEASEFLAGS = -O2 -D NDEBUG -combine -fwhole-program

HDPARMLIB    = libhdparm.so
SLSOURCES    = apt.c  hdparmdep.c sgio.c sysfs.c
SLHEADERS    = $(shell echo include/*.h)
SLOBJECTS  = $(SLSOURCES:.c=.o)

OBJECTS	   = $(SLOBJECTS) 

PREFIX = $(DESTDIR)/usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib

TARGET=${HDPARMLIB}


ALL=$(TARGET)


all:	$(ALL)


$(HDPARMLIB): $(SLOBJECTS)
	$(CC) $(FLAGS) $(CFLAGS) $(LDFLAGS) $(DEBUGFLAGS) -o $(HDPARMLIB) $(SLOBJECTS)


clean:
	rm -f $(TARGET) $(OBJECTS)

install:
	install -m644 $(HDPARMLIB) $(LIBDIR)
	install -m644 usr-local.conf /etc/ld.so.conf.d
	ldconfig
