---
title: "Run legacy PHP applications from command line"
categories: [articles]
tags: [php, symfony]
---

Imagine that you already have a trustfully application that you have been running for a while, but there is a couple of common patterns that make you consider that you need a command line interface (CLI) for you application:

* You are running some sort of cron that does a HTTP call to some endpoint to run some task on your website (like sending emails, etc)
* You have some operation that you want to automate (using chef or something) and HTTP request may not play that nicely
* You want to add some "super mega user" commands (like password reset or other) tha can be performed from command line, instead of hacking the DB.
* Insert your own reason here ...

So, how do we do this? especially without reinventing the well?

### The problem

Imagine that you have already a class on your application that performs your business logic, in this case, imagine that currently there is a form where you can edit a few values and then send the values to the server, that will be applied to the application by ```Example_Admin_ProcessConfigurationValues``` class bellow

```php
<?php

class Example_Admin_ProcessConfigurationValues
{
  public function process(array $values)
  {
    // do some magic stuff with the configuration values
  }
}
```

and now we want to supply the configuration values from command line as JSON file like this:

```json
{
  "configuration_key_a": "some value",
  "configuration_key_b": [
    "value 1",
    "value 2",
    "value 3",
  ]
  "configuration_key_c": "other value
}
```

So the goal is to be able to run a command like the following

```bash
php somecommand.php config.json
```

That means that we need to to the following steps:

1. Load the JSON file as a array
2. Call ```Example_Admin_ProcessConfigurationValues::process``` with that array
3. Done


### Symfony Console Component to the rescue

Instead of reinvented the well we can use Symfony components to build this, I imagine that you are already using composer, so you should already have a ```composer.json``` file that will looks like this:

```json
{
    "name": "example/project",
    "license": "MIT",
    "require": {
        "php": ">=5.4.0"
    },
    "require-dev": {
        "phpunit/phpunit": "~4.4"
    },
    "autoload": {
        "classmap": ["src/"]
    }
}
```

Then you can just use the [Symfony Console Component](http://symfony.com/doc/current/components/console/introduction.html) to be able to run your application from command line.

You just need to add ```symfony/console``` as a new dependency:

```bash
composer require symfony/console
```

And then you can create a new console command like the following example:

```php
<?php

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class Example_Command_ConfigFromJsonCommand extends Command
{
    protected function configure()
    {
        $this->setName('setup:load-json')
            ->setDescription('Load configurations values from a JSON file')
            ->addArgument(
                'jsonFile',
                InputArgument::REQUIRED,
                'Json file with configurations'
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $jsonFile = $input->getArgument('jsonFile');

        if (!file_exists($jsonFile)) {
            $output->writeln('Error: Json file does not exists');

            return 1;
        }

        $jsonFileContent = file_get_contents($jsonFile);

        $config = json_decode($jsonFileContent, true);

        if (!is_array($config)) {
            $output->writeln('Error: Json file does not seams valid');

            return 1;
        }

        // Call the existing code, with the content of the JSON file
        $oldClass = new Example_Admin_ProcessConfigurationValues();
        $oldClass->process($config);

        return 0;
    }
}
```

Alter that you need to register this, lets create a ```cli.php``` script that will be the entry point from the command line, and register the recently created command.

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Symfony\Component\Console\Application;

$application = new Application();

$application->add(new Example_Command_ConfigFromJsonCommand());

$application->run();
```

After that if you run ```cli.php``` from command line you should get this:

```bash
$ php cli.php
Console Tool

Usage:
  command [options] [arguments]

Options:
  -h, --help            Display this help message
  -q, --quiet           Do not output any message
  -V, --version         Display this application version
      --ansi            Force ANSI output
      --no-ansi         Disable ANSI output
  -n, --no-interaction  Do not ask any interactive question
  -v|vv|vvv, --verbose  Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

Available commands:
  help             Displays help for a command
  list             Lists commands
 setup
  setup:load-json  Load configurations values from a JSON file
```

and to run your newly create command you just need to do:

```bash
php cli.php setup:load-json config.json
```

Done!
