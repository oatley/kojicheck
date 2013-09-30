#!/bin/bash
chgrp mock /var/lib/mock 2> /dev/null
chgrp mock /var/cache/mock 2> /dev/null
chmod g+s /var/lib/mock
chmod g+s /var/cache/mock
/etc/rc.d/init.d/kojid restart
