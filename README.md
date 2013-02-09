autojenkins-rb
==============

Ruby API, wrappers and command-line client for Jenkins CI.

This tool can let you make calls to a Jenkins CI server to create, delete, build and query 
build projects. 

Usage
==============

You need to have a file, called mjenk in your $HOME (or specify it in the command-line tool)

<pre>
URL: http://ci.jenkins.org 
USER: username
PASSWD: [APIkey for the user, dont use your password]
</pre>

Once that file is created, you can use the mjenk utility to interact with the server:

To build a project:
<pre>
$ mjenk job -B -j JobName
</pre>

To delete a project
<pre>
$ mjenk job -d -j JobName
</pre>

To list all projects
<pre>
$ mjenk job
</pre>

<b>Note:</b> mjenk accepts a command as the first argument. In the examples
above, we use 'job'. The idea in the future is to add other commands in mjenk
to do more things, like interact with a vcs or other things. If no command is specified 
when calling mjenk, it defaults to 'job'.

Examples
========

Check out lib/tests.rb for some code examples to do stuff like:

- List all jobs (ListAll)
- Create jobs using other jobs as templates (CreateFromJob)
- Get information from a Build (GetBuildInfo)
- Get Job configuration as XML (GetConfig) 
- Get Job information (GetInfo)
