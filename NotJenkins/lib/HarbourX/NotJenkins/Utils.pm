package HarbourX::NotJenkins::Utils;

use common::sense;

use AnyEvent;
use Archive::Extract;
use Archive::Tar;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Data::Dump qw(dump);
use File::Find;
use File::Path;
use File::Slurp;
use File::Temp;
use Forks::Super DEBUG => 1;
use HTTP::Request;
use LWP;
use Promises qw(collect deferred);
use YAML::XS qw(LoadFile);




sub download_branch {
    my ($repo_name) = @_;

    my $project_sth = database->prepare(q{
        SELECT projects.id, repo_name, repo_owner, repo_user, repo_password, branch_name
        FROM projects
        LEFT JOIN branches ON projects.id = branches.project_id
        WHERE repo_name = ?
        AND enabled = 1
        LIMIT 1
    });

    $project_sth->execute($repo_name);

    my $repo = $project_sth->fetchall_hashref([]);

    my $download = HTTP::Request->new(
        GET => "https://github.com/".$repo->{repo_owner}."/".$repo->{repo_name}."/zipball/".$repo->{branch_name}
    );

    $download->authorization_basic($repo->{repo_user}, $repo->{repo_password});

    my $ua = LWP::UserAgent->new();

    my $zipfile = File::Temp->new( SUFFIX => '.zip', UNLINK => 1 );
    my $response = $ua->request($download, $zipfile->filename);

    if ($response->is_error) {
        die 'Could not download zipball: ' . $response->code . ' ' . $response->message;
    }

    if ($response->is_success) {
        my $extractor = Archive::Extract->new( archive => $zipfile->filename );
        $extractor->extract( to => File::Temp->newdir( CLEANUP => 0 ) );

        return $extractor->extract_path();
    }
}



sub download_pull_request {
    my ($branch_name) = @_;

    my $project_sth = database->prepare(q{
        SELECT repo_name, repo_owner, repo_user, repo_password
        FROM projects
        WHERE enabled = 1
        LIMIT 1
    });

    $project_sth->execute();

    my $repo = $project_sth->fetchall_hashref([]);

    my $download = HTTP::Request->new(
        GET => "https://github.com/".$repo->{repo_owner}."/".$repo->{repo_name}."/zipball/".$branch_name
    );

    $download->authorization_basic($repo->{repo_user}, $repo->{repo_password});

    my $ua = LWP::UserAgent->new();

    my $zipfile = File::Temp->new( SUFFIX => '.zip', UNLINK => 1 );
    my $response = $ua->request($download, $zipfile->filename);

    if ($response->is_error) {
        die 'Could not download zipball: ' . $response->code . ' ' . $response->message;
    }

    if ($response->is_success) {
        my $extractor = Archive::Extract->new( archive => $zipfile->filename );
        $extractor->extract( to => File::Temp->newdir( CLEANUP => 0 ) );

        return $extractor->extract_path();
    }
}





sub run_docker_tests {
    my ($options) = @_;

    my $config = LoadFile($options->{repo_dir}."/.leeroy.yml");

    my $cv = AnyEvent->condvar;

    my $insert_sth = database->prepare(q{
        INSERT INTO tests (build_id, title)
        VALUES (?, ?)
    });

    for my $test_title (keys %{$config->{tests}}) {
        $insert_sth->execute($options->{build_id}, $test_title);

        my $test_id = $insert_sth->{mysql_insertid};

        collect(
            map {
                async_cmd_run({
                    commandlist => $_->{Commands},
                    container   => $_->{Container},
                    test_id     => $test_id,
                })
            } $config->{tests}->{$test_title}
        )->then(
            sub {
                my $update_sth = database->prepare(q{
                    UPDATE builds
                    SET status = ?
                    WHERE id = ?
                });

                $update_sth->execute("pass", $options->{build_id});

                $cv->send({
                    output => \@_,
                });
            },
            sub {
                my $update_sth = database->prepare(q{
                    UPDATE builds
                    SET status = ?
                    WHERE id = ?
                });

                $update_sth->execute("fail",  $options->{build_id});

                $cv->croak( "ERROR" );
            }
        );
    }

    my $all_tests = $cv->recv;

    return $all_tests;
}




sub async_cmd_run {
    my ($options) = @_;

    my $d = deferred;

    fork {
        sub => sub {
            my $insert_sth = database->prepare(q{
                INSERT INTO commands (test_id, command, output)
                VALUES (?, ?, ?)
            });

            # FIXME TODO: This is trivially exploitable. We need to use the remote API rather than shelling out
            # The Perl bindings are out of date and need to be maintained, so this will do to validate the rest of the app
            my $alltests = join '\ ', @{$options->{commandlist}} if $options->{commandlist};

            # Build the image first
            my $dockerfile = $options->{Container}->{File};
            my $tag = $options->{Container}->{Tag};

            # TODO: /home/docker/End-User-CP is the path where we extracted the repo after downloading from GitHub
            # Will not work very well until boot2docer supports shared folders
            my $output = qx{
                docker build --tag="$tag" /home/docker/End-User-CP/$dockerfile;
                docker run -t -w /mnt/repo -v /home/docker/End-User-CP:/mnt/repo:ro $tag $alltests
            };

            $insert_sth->execute($options->{test_id}, $alltests, $output);
        },
        callback => {
            finish => sub {
                $d->resolve();
            },
            fail => sub {
                $d->reject();
            },
        }
    };

    return $d->promise;
}

1;
