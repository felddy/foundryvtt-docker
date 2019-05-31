# docker-postfix 🐳📮 #

[![Build Status](https://travis-ci.com/cisagov/docker-postfix.svg?branch=develop)](https://travis-ci.com/cisagov/docker-postfix)

Creates a Docker container with an installation of the
[postfix](http://postfix.org) MTA.  Additionally it has an IMAP
server ([dovecot](https://dovecot.org)) for accessing the archvies
of sent email.  All email is BCC's to the `mailarchive` account.

## Usage ##

A sample [docker composition](docker-compose.yml) is included in this repository.
To build and start the container use the command: `docker-compose up`

### Ports ###

By default this container will listen on the following ports:

- 1025: `smtp`
- 1587: `submission`
- 1993: `imaps`

### Environment Variables ###

Two environment variables are used to generate the configurations at runtime:

- `PRIMARY_DOMAIN`: the domain of the mail server
- `RELAY_IP`: (optional) an IP address that is allowed to relay mail without authentication

### Secrets ###

- `fullchain.pem`: public key
- `privkey.pem`: private key
- `mailarchive_password.txt`: password for the mailarchive user

### Volumes ###

Two optional volumes can be attached to this container to persist the
mail spool directory, as well as the logging directory.  (Note that
the mail logs are available using the docker log command.)

- `/var/spool/postfix`: mail queues
- `/var/log`: system logs

## Contributing ##

We welcome contributions!  Please see [here](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
