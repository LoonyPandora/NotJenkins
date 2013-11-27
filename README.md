NotJenkins
==========

An effort to replace Jenkins with a very small shell script



URL Structure
=============

POST /api/NotJenkins/hook/github/:type

:type can be pull_request, push, issue, etc


GET  /api/NotJenkins/pull

lists all pull requests we've built


GET  /api/NotJenkins/pull/:pull-id

Shows information about a pull request - including how many times we've built it


GET  /api/NotJenkins/pull/:pull-id/:build-id

Show a specific build, with full details about what failed. Every time a PR is update, we add a new build


