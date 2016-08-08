
nodesource-mirror
=================

A collection of scripts to help create and maintain mirrors of
https://deb.nodesource.com/
on plain dumb webspace.

For motivation, pros and cons, see [nodesource issue #71][nsi71].


Quick user's guide
------------------

* Install:
```bash
cd /var/www/my-node-mirror/htdocs
wget https://github.com/mk-pmb/nodesource-mirror-bash-wget/raw/master/upd_all.sh
chmod a+x upd_all.sh
```

* Configure (optional):
```bash
echo Options +Indexes >>.htaccess
wget https://github.com/mk-pmb/nodesource-mirror-bash-wget/raw/master/doc/exclude.example.txt
head exclude.*
```

* Run:
```bash
./upd_all.sh &
```



License
-------
ISC

  [nsi71]: https://github.com/nodesource/distributions/issues/71
