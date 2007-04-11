all: localizationStringsUpdate$(EXESUF)

localizationStringsUpdate$(EXESUF): localizationStringsUpdate.m
	gcc -Wall -O4 -F/System/Library/Frameworks -framework Cocoa -o $@ $^

clean:
	rm -f *.o *.a localizationStringsUpdate$(EXESUF) *.pod *~ */*~
