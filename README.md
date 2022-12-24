# SPM
The official package manager of the Swirl programming language.

## Compiling
### Requirement
 - A working [NIM](https://nim-lang.org/install.html) installation
 - My [utilities lib](https://github.com/0x454d505459/utilities-nim/)
 - At least one brain cell

### Process
 1) clone (or download the zip and extract): `git clone https://github.com/SwirlLang/spm.git`
 2) change directory: `cd spm`
 3) compile: `nim release spm.nim`
 4) get help: `./spm --help`

## Usage
- Getting help: `./spm --help`
- Install packages: `./spm install PACKAGE_NAME1 PACKAGE_NAME2`
- Uninstall packages : `./spm remove PACKAGE_NAME1 PACKAGE_NAME2`
- Search for packages: `./spm search PACKAGE_NAME1 PACKAGE_NAME2`
- Create a package: `./spm init`

## License
This software comes under the GPLv3 and later license. See [license.md](https://github.com/SwirlLang/spm/blob/main/license.md) for more info.

## Warning
Software comes as is, without any warrantee.
