These are scripts contributing by people that are running their own cocalc-docker servers.

- [cocalc_cleanup.py](./cocalc_cleanup.py): Python script for removing old accounts and old or deleted projects.

By studying the above script, you may get a sense of how to solve your own problems.   Cocalc-docker is hopefully pretty transparent -- it's just files in the /projects directory, and a PostgreSQL database that you can easily connect to as root in the container.   If you have written your own useful script, please make a pull request so we can add it here.
