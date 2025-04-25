# Dotfiles Server

This script is used to set up a new server with my dotfiles.

## OS Availability:
- [x] Ubuntu 20.04
- [x] Ubuntu 22.04
- [x] Debian 10

## Installation

Clone the repository and run the script:

```bash
git clone git@github.com:tanhongit/dotfiles_server.git
```

```bash
cd dotfiles_server
```

```bash
./install.sh a
```

> Note: You may need to make the script executable by running `chmod +x install.sh` before running it.
> 
> ```bash
> chmod +x install.sh
> ```

## Usage

The runner has the following commands:

| Command               | Description                  |
|-----------------------|------------------------------|
| `setup`, `s`, `a`     | Setup the server             |
| `ssh_port`, `sp`      | Change the SSH port          |
| `php`, `php-install`  | Install PHP version you want |
| `php_extension`, `pe` | Install PHP extensions       |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
