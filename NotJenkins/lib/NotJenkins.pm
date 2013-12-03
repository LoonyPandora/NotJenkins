package HarbourX::NotJenkins;

use Dancer ":syntax";
use Dancer::Plugin::Database;
use Data::Dump qw(dump);

use common::sense;


get qr{^ /NotJenkins/builds $}x => sub {
    my $pr_sth = database->prepare(q{
        SELECT pull_requests.id, github_number, github_title, github_state, github_created_at, github_updated_at, display_title, success
        FROM pull_requests
        LEFT JOIN projects ON project_id = projects.id
        LEFT JOIN (SELECT id, pull_id, success FROM builds ORDER BY id DESC LIMIT 1) AS builds ON builds.pull_id = pull_requests.id
        ORDER BY github_updated_at DESC, github_created_at DESC
    });

    my $branch_sth = database->prepare(q{
        SELECT branches.id, branch_name, branch_title, display_title, success
        FROM branches
        LEFT JOIN projects ON project_id = projects.id
        LEFT JOIN (SELECT id, branch_id, success FROM builds ORDER BY id DESC LIMIT 1) AS builds ON builds.branch_id = branches.id
        ORDER BY updated_at DESC
    });

    $pr_sth->execute();
    $branch_sth->execute();

    my $pull_requests = $pr_sth->fetchall_arrayref({});
    my $branches = $branch_sth->fetchall_arrayref({});

    # Numify `github_number`, `id` & truthify `success`
    for my $pr (@$pull_requests) {
        $pr->{id} += 0;
        $pr->{github_number} += 0;
        $pr->{success} = \1 if $pr->{success};
    }

    for my $branch (@$branches) {
        $branch->{id} += 0;
        $branch->{success} = \1 if $branch->{success};
    }

    return {
        pull_requests => $pull_requests,
        branches => $branches
    }
};



get qr{^ /NotJenkins/pull_requests/ (?<github_number> \d+ ) $}x => sub {
    my $pr_sth = database->prepare(q{
        SELECT pull_requests.id, github_number, github_title, github_state, github_created_at, github_updated_at, display_title, repo_html_url
        FROM pull_requests
        LEFT JOIN projects ON project_id = projects.id
        WHERE github_number = ?
        LIMIT 1
    });

    my $build_sth = database->prepare(q{
        SELECT builds.id, success, build_log, build_output_json AS build_output
        FROM builds
        WHERE pull_id = (SELECT id FROM pull_requests WHERE github_number = ? LIMIT 1)
        ORDER BY builds.id DESC
    });

    $build_sth->execute(captures->{github_number});
    $pr_sth->execute(captures->{github_number});

    my $pull_request = $pr_sth->fetchall_hashref([]);
    my $builds = $build_sth->fetchall_arrayref({});

    # Numify and truthify & expand stored JSON
    for my $build (@$builds) {
        $build->{id} += 0;
        $build->{success} = \1 if $build->{success};

        if ($build->{build_output}) {
            $build->{build_output} = from_json $build->{build_output};
        }
    }

    # Add the builds to the model
    $pull_request->{builds} = $builds;

    return $pull_request;
};


get qr{^ /NotJenkins/branches/ (?<branch_name> .+ ) $}x => sub {
    my $branch_sth = database->prepare(q{
        SELECT branches.id, branch_name, branch_title, display_title
        FROM branches
        LEFT JOIN projects ON project_id = projects.id
        WHERE branch_name = ?
        LIMIT 1
    });

    my $build_sth = database->prepare(q{
        SELECT builds.id, success, build_log, build_output_json AS build_output
        FROM builds
        WHERE branch_id = (SELECT id FROM branches WHERE branch_name = ? LIMIT 1)
        ORDER BY builds.id DESC
    });

    $branch_sth->execute(captures->{branch_name});
    $build_sth->execute(captures->{branch_name});

    my $branch = $branch_sth->fetchall_hashref([]);
    my $builds = $build_sth->fetchall_arrayref({});

    # Numify and truthify & expand stored JSON
    for my $build (@$builds) {
        $build->{id} += 0;
        $build->{success} = \1 if $build->{success};

        if ($build->{build_output}) {
            $build->{build_output} = from_json $build->{build_output};
        }
    }

    return {
        branch => $branch,
        builds => $builds
    };
};



1;
