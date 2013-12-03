package HarbourX::NotJenkins;

use Dancer ":syntax";
use Dancer::Plugin::Database;
use Data::Dump qw(dump);

use common::sense;


# Calling the database keyword will get you a connected database handle:
get "/NotJenkins/builds" => sub {

    my $sth = database->prepare(q{
        SELECT * FROM pull_requests
        LEFT JOIN projects ON project_id = projects.id
        LEFT JOIN builds ON pull_requests.id = pull_id
        ORDER BY github_updated_at, github_created_at DESC
    });

    $sth->execute();

    return {
        builds => $sth->fetchrow_hashref
    }
};



1;
