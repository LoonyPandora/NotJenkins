package HarbourX::NotJenkins;

use Dancer ":syntax";
use Dancer::Plugin::Database;
use Data::Dump qw(dump);
use Digest::MD5 qw(md5_hex);
use DateTime::Format::MySQL;
use DateTime::Format::RFC3339;
use HarbourX::NotJenkins::Utils;
use YAML::XS qw(LoadFile);
use Try::Tiny;

use common::sense;


get qr{^ /NotJenkins/tmp $}x => sub {
    my $insert_sth = database->prepare(q{
        INSERT INTO builds (project_id, branch_id, status)
        VALUES (?, ?, ?)
    });

    my $success = $insert_sth->execute(1, 1, "running");

    if ($success ne "0E0") {
        HarbourX::NotJenkins::Utils::run_docker_tests({
            repo_dir => "/Users/james/Code/End-User-CP",
            build_id => $insert_sth->{mysql_insertid},
        });
    }
};


get qr{^ /NotJenkins/builds $}x => sub {
    my $pr_sth = database->prepare(q{
        SELECT pull_requests.id, github_number, github_title, github_state, github_created_at, github_updated_at, display_title, status
        FROM pull_requests
        LEFT JOIN projects ON project_id = projects.id
        LEFT JOIN (SELECT id, pull_id, status FROM builds ORDER BY id DESC LIMIT 1) AS builds ON builds.pull_id = pull_requests.id
        ORDER BY github_updated_at DESC, github_created_at DESC
    });

    my $branch_sth = database->prepare(q{
        SELECT branches.id, branch_name, branch_title, display_title, status
        FROM branches
        LEFT JOIN projects ON project_id = projects.id
        LEFT JOIN (SELECT id, branch_id, status FROM builds ORDER BY id DESC LIMIT 1) AS builds ON builds.branch_id = branches.id
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
        # $pr->{success} = \1 if $pr->{success};
    }

    for my $branch (@$branches) {
        $branch->{id} += 0;
        # $branch->{success} = \1 if $branch->{success};
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
        SELECT builds.id, status
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
    }

    # Numify from the PR
    $pull_request->{github_number} += 0;

    # Add the builds to the model
    $pull_request->{builds} = $builds;

    return $pull_request;
};


get qr{^ /NotJenkins/branches/ (?<branch_name> .+ ) $}x => sub {
    my $command_sth = database->prepare(q{
        SELECT builds.id AS build_id, command, output AS command_output, title AS test_title, builds.status AS build_status, (SELECT output FROM commands WHERE test_id = tests.id ORDER BY id DESC LIMIT 1) AS test_output, display_title, repo_html_url
        FROM commands
        LEFT JOIN tests ON commands.test_id = tests.id
        LEFT JOIN builds ON tests.build_id = builds.id
        LEFT JOIN projects ON project_id = projects.id
        WHERE builds.branch_id = (SELECT id FROM branches WHERE branch_name = ? LIMIT 1)
    });

    $command_sth->execute(captures->{branch_name});
    my $commands = $command_sth->fetchall_arrayref({});

    # Numify, truthify, and expand stored data for JSON output
    my $output = {};
    my $meta = {};
    for my $command (@$commands) {
        push @{ $output->{builds}->{ $command->{build_id} }->{tests}->{ $command->{test_title} }->{log} }, $command;

        $meta->{repo_html_url} = $command->{repo_html_url};
        $meta->{display_title} = $command->{display_title};

        if (defined $command->{test_output}) {
            try {
                $command->{test_output} = from_json $command->{test_output};
            } catch {
                $command->{test_output} = undef;
            }
        }

        $output->{builds}->{ $command->{build_id} }->{status} = $command->{build_status};
        $output->{builds}->{ $command->{build_id} }->{tests}->{ $command->{test_title} }->{output} = $command->{test_output};
        $output->{builds}->{ $command->{build_id} }->{id} = $command->{build_id};
        $output->{builds}->{ $command->{build_id} }->{id} += 0;

        delete $command->{build_status};
        delete $command->{test_output};
        delete $command->{display_title};
        delete $command->{repo_html_url};
        delete $command->{test_title};
        delete $command->{build_id};
    }

    my @builds = map { $_ }
                 sort { $b->{id} <=> $a->{id} }
                 values %{$output->{builds}};

    return {
        repo_html_url => $meta->{repo_html_url},
        branch_title  => $meta->{display_title},
        builds => \@builds,
    };
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

        HarbourX::NotJenkins::Utils::run_docker_tests(
            HarbourX::NotJenkins::Utils::download_pull_request($params->{pull_request}->{head}->{label})
        );

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



1;
