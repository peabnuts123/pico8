# PICO8
This repo contains all my pico8 codes that aren't standalone projects. It's a sandbox project for experimenting and sharing code.

This repo excludes all files that might contain sensitive data e.g. config.txt. This means this repo is not 100% portable. It will work fine, but it might reset some settings on a fresh clone.

## VSCode
This repo is set up to launch easily from vscode, through the Debug menu or F5. Simply add a launch configuration for the cartridge you are working on and use environment variables to reference your files. Of course, you can run pico8 with the `-home` argument set to this location, and manually load the cartridge too, if you would prefer.

Apologies, at this time, the launch configurations are set up for Windows, and need some adaptation to be cross-platform.

### Configuring environment variables for launch.json in vscode
Copy the file `sample.env` and rename it to `.env`, keeping it in the root of the project.

Fill in the variables as follows:

| Variable   | Meaning |
|------------|---------|
| PICO8_ROOT | Path to the folder that contains the pico8 binary. i.e. `$PICO8_ROOT/pico8` should be enough to launch pico8 |