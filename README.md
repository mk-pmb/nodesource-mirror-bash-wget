
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

* (optional) Configure your mirror:
```bash
echo Options +Indexes >>.htaccess
wget -O exclude.local.txt https://github.com/mk-pmb/nodesource-mirror-bash-wget/raw/master/doc/exclude.example.txt
head exclude.*
```

* (optional) Preview what node versions will be downloaded:
```bash
./upd_all.sh _p             # see hints below
```

* Run:
```bash
./upd_all.sh &
```



Hints on download preview
-------------------------
* The preview may take a while to download the list of available products.
* Versions with an exclamation mark (`!`)
  in front of them are excluded by your config.
* If any version line has a `!` somewhere expect at start of line,
  something is very broken.
* Versions without `!` will be downlaoded.
* Option `_p` is like `-p` === `--list-products` except it uses `_`
  as the version separator, as will be expected for `exclude` config.



License
-------
ISC

  [nsi71]: https://github.com/nodesource/distributions/issues/71
