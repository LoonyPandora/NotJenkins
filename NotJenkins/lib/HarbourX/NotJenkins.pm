package HarbourX::NotJenkins;

use Dancer ":syntax";
use Dancer::Plugin::Database;
use Data::Dump qw(dump);
use Digest::MD5 qw(md5_hex);
use DateTime::Format::MySQL;
use DateTime::Format::RFC3339;
use HarbourX::NotJenkins::Utils;
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

        if ($build->{success}) {
            $build->{success} = \1
        } else {
            $build->{success} = \0;
        }

        if ($build->{build_output}) {
            $build->{build_output} = from_json $build->{build_output};

            # Add the MD5 of the filename so we can link directly to the line on GitHub
            for my $test (@{$build->{build_output}}) {
                for my $failure (@{$test->{failures}}) {
                    $failure->{filename_md5} = md5_hex($failure->{file});
                }
            }
        }
    }

    # Numify from the PR
    $pull_request->{github_number} += 0;

    # Add the builds to the model
    $pull_request->{builds} = $builds;

    return $pull_request;
};


get qr{^ /NotJenkins/branches/ (?<branch_name> .+ ) $}x => sub {
    my $branch_sth = database->prepare(q{
        SELECT branches.id, branch_name, branch_title, display_title, repo_html_url
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

    # Add the builds to the model
    $branch->{builds} = $builds;

    return $branch;
};


post qr{^ /NotJenkins/hooks/push $}x => sub {
    my $params = params();

    # Gets the raw branch name, instead of the full refspec
    my $branch_name = $params->{ref} =~ s{^refs/heads/}{}r;

    my $update_sth = database->prepare(q{
        UPDATE branches, projects
        SET branches.updated_at = UTC_TIMESTAMP()
        WHERE branches.branch_name = ?
        AND projects.repo_name = ?
        AND projects.repo_owner = ?
    });

    my $success = $update_sth->execute(
        $branch_name,
        $params->{repository}->{name},
        $params->{repository}->{owner}->{name},
    );


    if ($success ne "0E0") {
        die HarbourX::NotJenkins::Utils::download_branch($params->{repository}->{name});

        return {
            "message" => $success,
            "success" => \1
        };
    }

    return {
        "success" => \0,
        "message" => $success
    }
};


post qr{^ /NotJenkins/hooks/pull_request $}x => sub {
    my $params = params();

    my $insert_sth = database->prepare(q{
        INSERT INTO pull_requests (project_id, github_number, github_title, github_state, github_created_at, github_updated_at)
        VALUES ( (SELECT id FROM projects WHERE repo_name = ?), ?, ?, ?, ?, ? )
        ON DUPLICATE KEY UPDATE
            github_title = ?,
            github_state = ?,
            github_updated_at = ?
    });

    my $created_at = DateTime::Format::RFC3339->parse_datetime( $params->{pull_request}->{created_at} );
    my $updated_at = DateTime::Format::RFC3339->parse_datetime( $params->{pull_request}->{updated_at} );

    my $success = $insert_sth->execute(
        $params->{pull_request}->{base}->{repo}->{name},
        $params->{pull_request}->{number},
        $params->{pull_request}->{title},
        $params->{pull_request}->{state},
        DateTime::Format::MySQL->format_datetime($created_at),
        DateTime::Format::MySQL->format_datetime($updated_at),
        $params->{pull_request}->{title},
        $params->{pull_request}->{state},
        DateTime::Format::MySQL->format_datetime($updated_at)
    );


    if ($success) {
        return {
            "success" => \1
        };
    }

    return {
        "success" => \0,
        "message" => $success
    }
};



1;
