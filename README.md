<!-- -*- coding: utf-8, tab-width: 2 -*- -->

nodesource-mirror
=================

A collection of scripts to help create and maintain mirrors of
https://deb.nodesource.com/
on plain dumb webspace.


Quick user's guide
------------------

* Install:
```bash
cd /var/www/my-node-mirror/htdocs
wget https://github.com/mk-pmb/nodesource-mirror-bash-wget/raw/master/upd_all.sh
chmod a+x upd_all.sh
```

* Run:
```bash
./upd_all.sh &
```
