v0.1.0 (Yamashita, Yuu)

* Add `platform.family()`.
* Add `platform.packages.uninstall()` to uninstall packages.
* Add `platform.packages.update()` and `platform.packages.upgrade()`.

v0.1.1 (Yamashita, Yuu)

* Ignore the exit status of `yum ckeck-update -q -y` on RedHat.

v0.1.2 (Yamashita, Yuu)

* Use `lsb_release` to obtain the distro information.
* Add `platform.release()` and `platform.codename()`.
* platform.packages: Do not invoke commands actually if it is not required. Use bang methods (like `platform.packages.install!`) if you want to invoke them forcibly.
* Remove useless gem development dependencies.

v0.1.3 (Yamashita, Yuu)

* Fixed support for Amazon Linux. Thanks @tk0miya. ([#1](https://github.com/yyuu/capistrano-platform-resources/pull/1))
