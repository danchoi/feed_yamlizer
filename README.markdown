# feed_yamlizer

feed_yamlizer converts feeds into Ruby hashes and also processes feed entries
into plain text.

Basic usage

    ruby -I lib bin/feed2yaml  < test/ars.xml 
    ruby -I lib bin/feed2yaml 'http://feeds.arstechnica.com/arstechnica/index/'  
    TEST=1 ruby -I lib bin/feed2yaml 'http://feeds.arstechnica.com/arstechnica/index/'

More usage intructions to come.
