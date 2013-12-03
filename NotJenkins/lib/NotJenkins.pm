package HarbourX::NotJenkins;

use Dancer ":syntax";
use Dancer::Plugin::Database;
use Data::Dump qw(dump);

use JSON;

use common::sense;


# Calling the database keyword will get you a connected database handle:
get "/NotJenkins/builds" => sub {

    my $sth = database->prepare(q{
        SELECT pull_requests.id, github_number, github_title, github_state, github_created_at, github_updated_at, display_title, success
        FROM pull_requests
        LEFT JOIN projects ON project_id = projects.id
        LEFT JOIN (SELECT id, pull_id, success FROM builds ORDER BY id DESC LIMIT 1) AS builds ON builds.pull_id = pull_requests.id
        ORDER BY github_updated_at DESC, github_created_at DESC
    });

    $sth->execute();

    my $result = $sth->fetchall_arrayref({});

    # Numify `github_number`, `id` & truthify `success`
    for my $pr (@$result) {
        $pr->{id} += 0;
        $pr->{github_number} += 0;
        $pr->{success} = \1 if $pr->{success};
    }

    return {
        builds => $result
    }
};



1;
