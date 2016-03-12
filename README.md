# partial Data Generation for our SAP HANA Master Project

## how to

- install nodejs ([https://github.com/nodejs/node-v0.x-archive/wiki/Installing-Node.js-via-package-manager](https://github.com/nodejs/node-v0.x-archive/wiki/Installing-Node.js-via-package-manager) / [https://nodejs.org/en/download/](https://nodejs.org/en/download/))
- install with npm (node package manager)

        npm -g install coffee-script

- init project

        git clone https://github.com/josuakoschwitz/dbgenerator
        cd dbgenerator
        npm install

- run data cleanser (prepares geodata `DE.csv` – already done)

        coffee datacleanser.coffee

- run generator

        coffee app.coffee
